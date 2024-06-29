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

kmeansLoop:
    
    # Condicoes de paragem
    beqz s11, kmeansEnd             # Fez L iteracoes
    jal CompareCentroids
    beq a4, zero, kmeansEnd         # Centroids estabilizaram
    
    # Limpar pontos
    jal cleanScreen2
    
    # Atualizar agrupamentos
    jal assignCluster

    # Pintar pontos e centroides
    jal printClusters
    jal printCentroids
    
    # Guardar em oldCentroids 
    jal CopyCentroids

    # Recalcular centroides
    jal calculateCentroids
    
    addi s11, s11, -1              # Decrementar iteracoes
    
    j kmeansLoop

kmeansEnd:

    # Retornar mainKMeans
    lw ra, 0(sp)             
    addi sp, sp, 4
    jr ra

### initializeCentroids
# Inicializa os centroides com coordenadas pseudo-aleatorias
# Argumentos: nenhum
# Retorno: nenhum

initializeCentroids:
    addi sp, sp, -4
    sw ra, 0(sp)
    mv t0, s0                       # Passar o valor de k do s0 para t0
    la t1, centroids

initializeCentroids_loop:
    beqz t0, initializeCentroids_end
    jal generate_random      
    sw a0, 0(t1)                    # Valor do x
    jal generate_random
    sw a0, 4(t1)                    # Valor do y
    addi t1, t1, 8                  # Proximo par de coordenadas
    addi t0, t0, -1                 # k-1
    j initializeCentroids_loop

initializeCentroids_end:
    lw ra, 0(sp)             
    addi sp, sp, 4 
    jr ra                           # Voltar para a funcao mainKMeans

generate_random:
    li a7, 30                       # Numero da chamada do sistema (time_msec)
    ecall                           # Executar a chamada do sistema
    andi a0, a0, 0x1F               # Isolar os ultimos 5 bits para que esteja entre 0 e 31
    jr ra                           # Voltar para initializeCentroids_loop


### manhattanDistance
# Calcula a distancia de Manhattan entre (x0,y0) e (x1,y1)
# Argumentos:
# a0, a1: x0, y0
# a2, a3: x1, y1
# Retorno:
# a0: distance

manhattanDistance:
    sub t0, a0, a2                  # (x0-x1)
    sub t1, a1, a3                  # (y0-y1)
    # Encontra |x0-x1|
    bge t0, x0, continue
    neg t0, t0

continue:
    # Encontra |y0-y1|
    bge t1, x0, continue_2
    neg t1, t1

continue_2: 
    add a0, t0, t1                  # |dx|+|dy|
    jr ra

### nearestCluster
# Determina o centroide mais perto de um dado ponto (x,y)
# Argumentos:
# a0, a1: (x, y) point
# Retorno:
# a0: cluster index

nearestCluster:
    # Guarda o retorno de nearestCluster
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    li t6, 0x3E                      # Inicial maior distancia (|31-0|+|31-0|)
    li t5, 0                         # Index do cluster mais proximo a retornar

    li t2, 0                         # Index do cluster atual
    la s2, k
    lw s2, 0(s2)

    la s1, centroids

minDistanceLoop:
    beq t2, s2, minDistanceEnd       # Terminar depois de testar com todos os clusters
    
    # Carregar coordenadas do centroide atual
    lw a2, 0(s1)                     # x do centroide
    lw a3, 4(s1)                     # y do centroide

    jal manhattanDistance
    mv t4, a0                        # Guardar a distancia atual 
    lw a0, 4(sp)                     # Recuperar coordenada

    blt t4, t6, assignDistance       # Se distancia atual < distancia anterior

contMinDistanceLoop:
    addi s1, s1, 8                   # Proximas coordenadas de centroide
    addi t2, t2, 1                   # Proximo index de cluster
    j minDistanceLoop

assignDistance:
    mv t6, t4                        # Atualizar a menor distancia
    mv t5, t2                        # Atualizar index de cluster com a menor distancia
    j contMinDistanceLoop

minDistanceEnd:

    # Retornar nearestCluster
    mv a0, t5
    lw ra, 0(sp)             
    addi sp, sp, 8
    jr ra

### assignCluster
# Atribui a cada ponto o centroide mais proximo
# Argumentos: nenhum
# Retorno: nenhum

assignCluster:

    # Guardar o retorno de assignCluster
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Inicializar variaveis
    lw s9, n_points
    la s8, points
    la s7, clusters

assignClusterLoop:
    beq s9, x0, assignClusterEnd       # Se iterou todos os pontos, terminar
    
    # Chamar nearestCluster para retornar indice do ponto atual 
    lw a0, 0(s8)
    lw a1, 4(s8)
    jal nearestCluster
    sw a0, 0(s7)
    
    # Passar para o proximo ponto sem cluster atualizado
    addi s9, s9, -1
    addi s8, s8, 8
    addi s7, s7, 4
    j assignClusterLoop

assignClusterEnd:
    
    # Retorna assignCluster
    lw ra, 0(sp)             
    addi sp, sp, 4
    jr ra

### CopyCentroids
# Copia os centroids atuais para oldCentroids
# Arguments: nenhum
# Returns: nenhum

CopyCentroids:

    la t0, centroids
    la s1, oldCentroids
    lw s2, k
    li t1, 0                            # Contador de centroids

CopyCentroids_loop:

    beq t1, s2, CopyCentroids_end

    lw t4, 0(t0)                        # Carregar x de centroids
    sw t4, 0(s1)                        # Guardar x em oldCentroids
    lw t4, 4(t0)                        # Carregar y from centroids
    sw t4, 4(s1)                        # Guardar y de oldCentroids

    addi t0, t0, 8                      # Avancar no centroids
    addi s1, s1, 8                      # Avancar no old_centroids
    addi t1, t1, 1                      # Incrementar contador

    j CopyCentroids_loop

CopyCentroids_end:
    jr ra

### CompareCentroids
# Verifica se dois vetores sao iguais
# Arguments: nenhum
# Returns: nenhum

CompareCentroids:
    la t0, centroids
    la s1, oldCentroids
    lw s2, k
    li t1, 0
    li a4, 1                            # Retorno da funcao: 1 sao diferentes, 0 sao iguais

CompareCentroids_loop:

    beq t1, s2, Equal                   # Se percorreu todos os valores e sao iguais
    
    lw t2, 0(t0)
    lw t3, 0(s1)
    bne t2, t3, NotEqual                # Se algum valor no vetor e diferente, nao sao iguais e continuar

    addi t0, t0, 4
    addi s1, s1, 4
    addi t1, t1, 1

    j CompareCentroids_loop

NotEqual:
    jr ra

Equal:
    li a4, 0                            # Sao iguais, deve terminar o algoritmo
    jr ra


### cleanScreen2
# Limpa apenas os pontos pintados/iluminados
# Argumentos: nenhum
# Retorno: nenhum

# OPTIMIZATION: Limpar apenas os centroides representados apos cada iteracao. Nao e 
#               necessario o cleanscreen inicial, pois o resto, coordenadas nao ocupadas
#               por pontos ou centroids, ja estao limpas. Propomos tambem nao eliminar os pontos
#               a cada iteracao, tendo em conta que acabarao sempre pintados, minimizando os custos
#               de memória e tempo.
        
cleanScreen2:
    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)

    # Load the color for clearing points
    li a2, WHITE                         # Cor para limpar o ponto

    # Limpar centroids
    la s0, oldCentroids            
    lw s1, k                   
    jal printArray                       # Pintar vetor oldcentroids de branco

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra                    
