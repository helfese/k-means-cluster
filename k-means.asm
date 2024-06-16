.text

    # Inicializa k
    la s0, k
    lw s0, 0(s0)
    addi t0, s0, -1
    bgt t0, x0, 12              # Condicao quando k = 1 ou k > 1

    # Chama funcao principal para k=1
    jal mainSingleCluster
    j end_program

    # Chama funcao principal para k>1
    jal mainKMeans

end_program:
    # Termina o programa
    li a7, 10
    ecall

### cleanScreen
# Limpa todos os pontos do ecra
# Argumentos: nenhum
# Retorno: nenhum

cleanScreen:
    li t0, WHITE                # Carregar o estado de ponto limpo
    li t1, LED_MATRIX_0_BASE    # Encontrar o primeiro ponto do ecra
    la t2, LED_MATRIX_0_SIZE    # Carregar o tamanho do ecra
    add t2, t1, t2              # Encontrar o utlimo ponto do ecra
# Iteracao para limpar cada ponto
loopLed:
    sw t0, 0(t1)                # Limpar o ponto
    addi t1, t1, 4              # Proximo ponto
    bne t1, t2, loopLed         # Iterar ate ao ultimo ponto
    jr ra                       # Retornar cleanScreen

### printPoint
# Pinta o ponto (x,y) na LED matrix com a cor passada por argumento
# Argumentos:
# a0: x
# a1: y
# a2: cor
# Retorno: nenhum

printPoint:
    li a3, LED_MATRIX_0_HEIGHT
    sub a1, a3, a1
    addi a1, a1, -1  
    li a3, LED_MATRIX_0_WIDTH
    mul a3, a3, a1
    add a3, a3, a0
    slli a3, a3, 2
    li a0, LED_MATRIX_0_BASE
    add a3, a3, a0
    sw a2, 0(a3)
    jr ra                        # Retornar printPoint

