#lang br
(require brag/support)

; used src/lexer.mll as reference
(define netverif-lexer
    (lexer-srcloc
        ["\n" (token 'NEWLINE lexeme)]
        [whitespace (token lexeme #:skip? #t)]
        ; keywords from typed front-end
        [(:or "type" "name" "const" "forall" "clauses" "select" "noselect"
            "set") (token lexeme lexeme)]
        ; keywords from untyped front-end
        [(:or "fun" "data" "equation" "reduc" "query" "nounif" "param" "not"
            "elimtrue" "pred") (token lexeme lexeme)]
        [(from/stop-before "(*" "*)") (token 'COMMENT lexeme)]))

(provide netverif-lexer)
