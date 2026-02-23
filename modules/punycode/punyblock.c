/*
 * Unbound dynlib module that blocks DNS queries for punycode (IDN) domains.
 *
 * Punycode-encoded labels in DNS start with the "xn--" prefix (RFC 3492).
 * This module inspects the wire-format query name and refuses resolution
 * for any domain containing such a label.
 *
 * Build: gcc -shared -Wall -Werror -fpic -fvisibility=hidden -o punyblock.so punyblock.c
 */

#include <stdint.h>
#include <stddef.h>

#define EXPORT __attribute__((visibility("default")))

/* -------------------------------------------------------------------------
 * Unbound C ABI types
 * ------------------------------------------------------------------------- */

#define MAX_MODULE 16
#define RCODE_REFUSED 5

enum module_ext_state {
    module_state_initial = 0,
    module_wait_reply,
    module_wait_module,
    module_restart_next,
    module_wait_subquery,
    module_error,
    module_finished
};

enum module_ev {
    module_event_new = 0,
    module_event_pass,
    module_event_reply,
    module_event_noreply,
    module_event_capsfail,
    module_event_moddone,
    module_event_error
};

struct query_info {
    uint8_t*  qname;
    size_t    qname_len;
    uint16_t  qtype;
    uint16_t  qclass;
    void*     local_alias;
};

struct module_env {
    char _opaque;
};

struct outbound_entry {
    char _opaque;
};

struct module_qstate {
    struct query_info       qinfo;
    uint16_t                query_flags;
    int                     is_priming;
    int                     is_valrec;
    void*                   reply;
    void*                   return_msg;
    int                     return_rcode;
    void*                   reply_origin;
    void*                   blacklist;
    void*                   region;
    void*                   errinf;
    int                     curmod;
    enum module_ext_state   ext_state[MAX_MODULE];
    void*                   minfo[MAX_MODULE];
    struct module_env*      env;
};

/* -------------------------------------------------------------------------
 * Unbound logging
 * ------------------------------------------------------------------------- */

void log_info(const char* fmt, ...);

/* -------------------------------------------------------------------------
 * Internal helpers
 * ------------------------------------------------------------------------- */

/* Returns 1 if the 4 bytes at `p` match "xn--" case-insensitively, 0 otherwise. */
/* Caller must ensure p points to at least 4 readable bytes. */
static int
is_xn_prefix(const uint8_t *p)
{
    return (p[0] == 'x' || p[0] == 'X') &&
           (p[1] == 'n' || p[1] == 'N') &&
            p[2] == '-' &&
            p[3] == '-';
}

/* -------------------------------------------------------------------------
 * Exported module functions
 * ------------------------------------------------------------------------- */

EXPORT int init(struct module_env* env, int id) {
    (void)env;
    (void)id;
    log_info("punyblock: loaded");
    return 1;
}

EXPORT void deinit(struct module_env* env, int id) {
    (void)env;
    (void)id;
    log_info("punyblock: unloaded");
}

EXPORT void operate(struct module_qstate* qstate, enum module_ev event, int id, struct outbound_entry* entry) {
    (void)entry;

    if (event == module_event_new || event == module_event_pass) {
        /* New query or passed from a previous module in the chain.
         * This is where we inspect the wire-format qname for punycode
         * labels (any label starting with "xn--", case-insensitive).
         *
         * Wire format: sequence of length-prefixed labels, terminated
         * by a zero-length label (single 0x00 byte).
         *   e.g. "\x03xn-\x05-11ba\x02de\x00"
         *
         * If a punycode label is found:
         *   - set return_rcode = 5 (REFUSED, honest policy block)
         *   - set return_msg = NULL (no answer payload needed)
         *   - set ext_state = module_finished (done, skip downstream)
         *
         * If no punycode label is found:
         *   - set ext_state = module_wait_module (pass to next module)
         */

        /* Walk wire-format qname labels, checking each for the "xn--" prefix.
         *
         * Wire format: <len><label bytes> ... <len><label bytes> <0x00>
         * We never read past qname_len bytes. If a label length field would
         * cause us to exceed that bound the qname is malformed — break and
         * pass the query through rather than refusing on bad input.
         */
        {
            const uint8_t *p   = qstate->qinfo.qname;
            size_t         rem = qstate->qinfo.qname_len;
            int            blocked = 0;

            while (rem > 0) {
                uint8_t label_len = p[0];

                /* Zero-length label = root label, end of qname. */
                if (label_len == 0)
                    break;

                /* RFC 1035 §2.3.4: max label length is 63. Values above
                 * (compression pointers, extended label types) must not
                 * appear in a decompressed qname — treat as malformed. */
                if (label_len > 63)
                    break;

                /* Bounds check: length byte + label content must fit. */
                if ((size_t)(label_len + 1) > rem)
                    break; /* malformed — pass through */

                /* Punycode label: length >= 4 and starts with "xn--". */
                if (label_len >= 4 && is_xn_prefix(p + 1)) {
                    blocked = 1;
                    break;
                }

                /* Advance to next label. */
                p   += label_len + 1;
                rem -= label_len + 1;
            }

            if (blocked) {
                log_info("punyblock: refused query (punycode domain)");

                qstate->return_msg        = NULL;
                qstate->return_rcode      = RCODE_REFUSED;
                qstate->ext_state[id]     = module_finished;
            } else {
                qstate->ext_state[id] = module_wait_module;
            }
        }
    } else if (event == module_event_moddone) {
        /* Downstream module finished; its return_rcode and return_msg
         * are already set. Mark ourselves done. */
        qstate->ext_state[id] = module_finished;
    } else {
        /* Unexpected event (reply, noreply, capsfail, error).
         * These should not reach us since we never issue outbound
         * queries ourselves. Signal an error so unbound can handle
         * it gracefully. */
        qstate->ext_state[id] = module_error;
    }
}

EXPORT void inform_super(struct module_qstate* qstate, int id, struct module_qstate* super) {
    (void)qstate;
    (void)id;
    (void)super;
}

EXPORT void clear(struct module_qstate* qstate, int id) {
    (void)qstate;
    (void)id;
}

EXPORT size_t get_mem(struct module_env* env, int id) {
    (void)env;
    (void)id;
    return 0;
}
