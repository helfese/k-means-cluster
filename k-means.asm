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

### printClusters
# Pinta os agrupamentos na LED matrix com a cor correspondente.
# Argumentos: nenhum
# Retorno: nenhum

printClusters:
    # Guarda o retorno de printClusters
    addi sp, sp, -4
    sw ra, 0(sp)

    # Inicializar contadores
    la s0, points
    lw s1, n_points              # Numero de pontos
    lw s5, k                     # Numero de clusters
    
    # verifica se k == 1
    mv t0, s5
    addi t0, t0, -1
    bnez t0, printMultipleCluster

k_equals_1:
    # PrintClusters para k = 1
    # pinta todos os pontos a vermelho
    li a2, RED
    jal printArray
    j printArray_end
    
printMultipleCluster:
    # PrintClusters for k > 1
    la s2, clusters               # Vetor clusters
    la s3, colors                 # Vetor colors

printClusters_loop:
    # Verificar se todos os pontos foram pintados
    beq s1, zero, printArray_end

    lw a0, 0(s0)  # x
    lw a1, 4(s0)  # y

    lw t0, 0(s2)                  # Indice cluster do ponto
    slli t1, t0, 2                # Multiplica t0 por 4

    add t1, s3, t1                # Seleciona cor do ponto com base no cluster

    lw a2, 0(t1)            
    jal printPoint

    # Avancar para o proximo ponto
    addi s0, s0, 8                # Proximo par de coordenadas
    addi s2, s2, 4                # Proximo indice vetor cluster
    addi s1, s1, -1               # Decrementar o contador de pontos
          
    j printClusters_loop
    
### printArray
# Pinta os pontos no vetor fornecido.
# Argumentos:
#   s0: endere�o base dos pontos
#   s1: n�mero de pontos
#   a2: cor
# Retorno: nenhum

printArray:
    # Guarda o retorno de printArray
    addi sp, sp, -4
    sw ra, 0(sp)
    
printArray_loop:
    # Verificar se todos os pontos foram pintados
    beq s1, zero, printArray_end

    # Obter as coordenadas do ponto
    lw a0, 0(s0)  # x
    lw a1, 4(s0)  # y

    # Chamar printPoint para pintar o ponto
    jal printPoint

    # Avancar para o proximo ponto
    addi s0, s0, 8                # Proximo par de coordenadas
    addi s1, s1, -1               # Decrementar o contador de pontos

    j printArray_loop

printArray_end:
    # Restaurar registradores e retorna
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

### calculateCentroids
# Calcula os k centroides, a partir da distribuicao atual de pontos associados a cada agrupamento (cluster)
# Argumentos: nenhum
# Retorno: nenhum

calculateCentroids:
    # Guarda o retorno de calculateCentroids
    addi sp, sp, -4         
    sw ra, 0(sp)
    
    lw s3, n_points                # Numero de pontos
    lw s5, k                       # Numero de clusters
    la s6, centroids               # Vetor de centroids

    li t1, 0                       # Cluster inicial

    # Se k == 1
    mv t0, s5
    addi t0, t0, -1
    beqz t0, calculateCentroidSingleCluster

# Multiple Clusters Calculation
calcentroidOuterLoop:
    # Verificar se todos os centroids foram calculados
    bge t1, s5, calcCentroidEnd

    # Inicializar ponteiros de points e clusters
    la s0, points
    la s4, clusters
    # Obter as coordenadas do centroid
    li s1, 0
    li s2, 0

    mv t0, s3                       # Inicializar contador de pontos totais
    li t5, 0                        # Inicializar contador de pontos no cluster atual
    
calcCentroidInnerLoop:
    beq t0, zero, calcCentroidIEndInner

    lw t2, 0(s4)                    # Ver cluster do ponto atual

    bne t2, t1, NextPoint

    # Concatena os valores de x e y se o ponto pertence ao cluster atual
    lw t3, 0(s0)
    add s1, s1, t3
    lw t4, 4(s0)
    add s2, s2, t4
    addi t5, t5, 1                  # Incrementar numero de pontos no cluster

NextPoint:
    # Avancar para o proximo ponto
    addi s0, s0, 8                  # Proximo par de coordenadas
    addi s4, s4, 4                  # Cluster do proximo ponto
    addi t0, t0, -1                 # Decrementar o contador de pontos totais
    
    j calcCentroidInnerLoop

calcCentroidIEndInner:
    # Verificar se o numero de pontos no cluster e zero
    beqz t5, calcCentroidRandomInit

    # Calcula media de x e y
    divu s1, s1, t5                 # Calcular media de x
    divu s2, s2, t5                 # Calcular media de y

    j calcCentroidStore

calcCentroidRandomInit:
    # Gerar coordenadas aleatorias quando cluster nao tem pontos
    jal generate_random
    mv s1, a0                       # Guardar valor aleatorio de x
    jal generate_random
    mv s2, a0                       # Guardar valor aleatorio de y

calcCentroidStore:
    # Guardar medias no vetor centroids
    sw s1, 0(s6)
    sw s2, 4(s6)

    # Avancar para calculo proximo centroid
    addi s6, s6, 8                  # Passar para proximo centroid
    addi t1, t1, 1                  # Incrementar indice cluster

    j calcentroidOuterLoop

# Single Cluster Calculation
calculateCentroidSingleCluster:
    # Inicializar ponteiros de points
    la s0, points
    mv t0, s3                       # Inicializar contador de pontos (s3 = num pontos)

    # Obter as coordenadas do centroid
    li s1, 0
    li s2, 0

calcCentroidLoop:
    # Verificar se todos os pontos foram iterados
    beq t0, zero, calcCentroidEndSingle

    # Concatenar os valores de x
    lw t1, 0(s0)
    add s1, s1, t1
    # Concatenar os valores de y
    lw t2, 4(s0)
    add s2, s2, t2 
    
    # Avancar para o proximo ponto
    addi s0, s0, 8                  # Proximo par de coordenadas
    addi t0, t0, -1                 # Decrementar o contador de pontos
    
    j calcCentroidLoop

calcCentroidEndSingle:
    divu s1, s1, s3                 # Calcular media de x
    divu s2, s2, s3                 # Calcular media de y

    # Guardar medias no vetor centroids
    la s0, centroids
    sw s1, 0(s0)
    sw s2, 4(s0)

calcCentroidEnd:
    lw ra, 0(sp)            
    addi sp, sp, 4
    jr ra                   


### printCentroids
# Pinta os centroides na LED matrix
# Nota: deve ser usada a cor preta (black) para todos os centroides
# Argumentos: nenhum
# Retorno: nenhum
    
printCentroids:
    # Guardar o retorno de printCentroids
    addi sp, sp, -4
    sw ra, 0(sp)

    # Inicializar contadores
    la s0, centroids
    lw s1, k                        # Numero de centroides
    li a2, BLACK
    jal printArray_loop             # Pinta vetor centroids de preto
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
    
### mainSingleCluster
# Funcao principal para k = 1
# Argumentos: nenhum
# Retorno: nenhum

mainSingleCluster:

    # Guardar o retorno de mainSingleCluster
    addi sp, sp, -4
    sw ra, 0(sp)

    jal cleanScreen

    jal printClusters

    jal calculateCentroids

    jal printCentroids
    
    # Retorna mainSingleCluster
    lw ra, 0(sp)             
    addi sp, sp, 4
    addi ra, ra, 4               
    jr ra

### mainKMeans
# Executa o algoritmo *k-means*
# Argumentos: nenhum
# Retorno: nenhum

mainKMeans:

    # Guardar o retorno de mainKMeans
    addi sp, sp, -4
    sw ra, 0(sp)

    # Inicializar o contador de l-iteracoes
    lw s11, L
    
    # Inicializar ecra
    jal cleanScreen
    
    # Inicializar coordenadas centroids aleatorios
    jal initializeCentroids
