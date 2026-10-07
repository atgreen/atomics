# EGCL CAS backend

The `egcl` branch adds `#+egcl` support for `atomics:cas` using
`egcl-ext:cas`. Atomics returns a Boolean success flag; EGCL's primitive
returns the observed old value. The adapter preserves that distinction and
evaluates place subforms, the expected value and the replacement once, in
that order.

Supported places are CAR/CDR, SVREF, SYMBOL-VALUE, SYMBOL-PLIST,
instance-allocated SLOT-VALUE, structure accessors and special variables.
Lexical symbol macros resolving to these places are supported. Arbitrary
lexical variables, custom atomic expanders and raw memory places are not.
Only the corresponding CAS capability features are advertised.

This is a CAS-only port for cl-cancel's lazy initialization. ATOMIC-INCF and
ATOMIC-DECF still report IMPLEMENTATION-NOT-SUPPORTED on EGCL. The upstream
portable POP/PUSH/UPDATE fallbacks have not been validated for concurrent
use; this port is not a claim that the entire Atomics API is supported.

The regression file `egcl-tests.lisp` runs after loading `atomics.lisp` or
the ASDF system. It checks all advertised place categories, success and
failure, dynamic binding isolation, evaluation order, symbol macros, and
a four-thread CAS counter. It requires an EGCL build with the extension
macro lookup correction tracked as Evergreen `bliss-o2deg`.
