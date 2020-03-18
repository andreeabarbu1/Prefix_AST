%include "includes/io.inc"
%define NUM_MAX_OP 400

extern getAST
extern freeAST

section .bss
    ; La aceasta adresa, scheletul stocheaza radacina arborelui
    root: resd 1
    expr: resd NUM_MAX_OP
    numar_ascii: resq NUM_MAX_OP
    vector_inversat: resd NUM_MAX_OP
    
section .data
    index dd 0
    numar dd 0
    ok dd 0
    
section .text
global main
main:
    mov ebp, esp; for correct debugging
    ; NU MODIFICATI
    push ebp
    mov ebp, esp
    
    ; Se citeste arborele si se scrie la adresa indicata mai sus
    call getAST
    mov [root], eax
    
    ; Implementati rezolvarea aici:
    xor eax, eax
    mov eax, [root]
    push eax
    push eax
    
    ; parcurg arborele si retin adresele char-urilor
    ; in vectorul expr
parcurgere:
    mov ecx, eax ; adresa nodului curent
    mov ebx, [ecx] ; adresa char-ului
    xor ecx, ecx
    mov ecx, [index]
    ; la pozitia index a vectorului expr pun adresa
    ; char-ului nodului curent
    mov dword [expr + (4 * ecx)], ebx
    inc dword [index]
    ; verific daca are fiu in stanga 
    mov ebx, [eax + 4]
    cmp ebx, 0
    jz frunza_stanga
    ; trec la urmatorul element din stanga
    mov eax, ebx
    push eax
    jmp parcurgere
    ; daca nodul e frunza, adresa lui va fi nula
frunza_stanga:
    mov dword [eax + 4], 0
    pop eax
    ; in eax va fi retinuta adresa nodului anterior frunzei
    ; pentru a se realiza parcurgerea in dreapta
    pop eax
    jmp dreapta
    ; frunza din dreapta va deveni si ea nula
dreapta:   
    mov edx, [eax + 8]
    mov dword [eax + 8], 0
    ; daca arborele este parcurs, se iese, daca nu
    ; se va continua parcurgerea
    cmp edx, 0
    jz final
    mov eax, edx
    push eax
    jmp parcurgere
final:
    xor edi, edi
    xor ecx, ecx

    ; convertirea din cod ascii in numar
convert:
    mov eax, dword [expr + 4 * edi]
    mov ebx, [eax]
    ; in numar_ascii retin codul ascii ce trebuie convertit
    mov dword [numar_ascii], ebx
    mov ecx, 1
valoare_ascii:
    mov edx, [eax + ecx]
    mov dword [numar_ascii + ecx], edx
    inc ecx
    cmp ecx, 4
    jne valoare_ascii
    ; in numar o sa retin numarul converit
    mov dword [numar], 0
    xor ecx, ecx
    ; in ebx se afla codul ascii curent
    ; am tratat special cazurile cand numarul este 0 sau 
    ; este un operator
    cmp ebx, '0'
    je zero
    cmp ebx, '+' 
    je plus
    cmp ebx, '-' 
    je minus
    cmp ebx, '*' 
    je inmul
    cmp ebx, '/' 
    je imp
    ; convertesc codul ascii din numar_ascii in numar
    ; si il retin in variabila numar
convert_byte:
    ; retin in bl caracterul de la indexul ecx
    mov bl, byte [numar_ascii + ecx]
    test bl, bl ; verific daca s-a ajuns la final
    je out
    ; tratez separat cazul cand numarul e negativ
    cmp bl, '-' 
    je negativ
    ; fiecare byte va fi transformat in numar intreg
    ; si aplic formula numar = numar * 10 + bl
    ; pentru a converti numarul
    sub bl, 48 
    mov eax, 10
    mul dword [numar]
    movsx ebx, bl
    add eax, ebx
    mov dword [numar], eax
    inc ecx ; nr de caractere
    jmp convert_byte
negativ:
    mov dword [ok], 1 
    ; pentru a verifica ulterior daca numarul curent este negativ
    mov dword [ok], 1
    inc ecx
    jmp convert_byte
zero:
    push 0
    jmp out
plus:
    push '+'
    jmp out
minus:
    push '-'
    jmp out
inmul:
    push '*'
    jmp out
imp:
    push '/'
    jmp out    
out:
    ;initializez numar_ascii cu 0 pentru urmatoarea prelucrare
    mov dword [numar_ascii], 0   
    mov ecx, 3
initializare:
    mov dword [numar_ascii + ecx], 0
    loop initializare
    mov eax, [numar]
    ; daca numarul e negativ inmultim cu -1
    cmp dword [ok], 1
    jne nu_e_negativ
    mov eax, -1
    imul dword [numar]
nu_e_negativ:
    cmp eax, 0
    jz nu_e_numar
    ; pun pe stiva fiecare numar convertit
    push eax
nu_e_numar:
    mov dword [ok], 0
    inc edi  
    ; in [index] se afla numarul elementelor din vectorul expr  
    cmp edi, [index]
    jnz convert

    ; retin in vector_inversat numerele convertite si operanzii 
    ; ce se afla pe stiva
    xor ecx, ecx
    mov dword [index], 0
inversare_elemente:
    pop eax
    mov dword [vector_inversat + (4 * ecx)], eax
    inc ecx
    inc dword [index]
    ;verific daca mai sunt elemente pe stiva
    cmp ebp, esp
    jg inversare_elemente
    
    ; voi calcula expresia prefixata inversata cu ajutorul stivei:
    ; parcurg vectorul vector_inversat si pun valoarea curenta pe stiva,
    ; cand intalnesc un operator scot trei elemente de pe stiva (primul 
    ; este operatorul, ceilalti doi operanzii) si realizez operatia, samd
    xor ecx,ecx 
calcul:
    mov eax, dword [vector_inversat + 4 * ecx]
    push eax
    cmp eax, '-'
    jz calc_minus   
    cmp eax, '+'
    jz calc_plus
    cmp eax, '*'
    jz calc_inmul
    cmp eax, '/'
    jz calc_imp
continua_calcul:
    inc ecx
    ; verific daca mai sunt elemente de parcurs in vecor
    cmp ecx, [index]
    jnz calcul
    cmp ecx, [index]
    jz finalul_operatiei
calc_minus:
    pop edx
    pop eax
    pop ebx
    sub eax, ebx
    push eax
    jmp continua_calcul
calc_plus:
    pop edx
    pop eax
    pop ebx
    add eax, ebx
    push eax
    jmp continua_calcul
calc_inmul:
    pop edx
    pop eax
    pop ebx
    imul ebx
    push eax
    jmp continua_calcul
calc_imp:
    pop edx
    xor edx, edx
    pop eax ; deimpartit
    pop ebx ; impartitor
    ; verific daca deimpartitul e negativ
    cmp eax, 0
    jl demp_negativ
impartire:    
    idiv ebx
    push eax
    jmp continua_calcul
    ; tratez un caz separat pentru deimpartit negativ
demp_negativ:
    ; in edx retin -1 pentru a pastra semnul
    mov edx, 0xFFFFFFFF
    jmp impartire     
finalul_operatiei:
    ; rezultatul calcului este ultimul element din stiva
    pop eax
    PRINT_DEC 4, eax
    
    ; NU MODIFICATI
    ; Se elibereaza memoria alocata pentru arbore

    push dword [root]
    call freeAST
    
    xor eax, eax
    leave
    ret