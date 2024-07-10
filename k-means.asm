.text

    la s0, k
    lw s0, 0(s0)
    addi t0, s0, -1
    bgt t0, x0, 12

    jal mainSingleCluster
    j endProgram
    jal mainKmeans

endProgram:

    li a7, 10
    ecall

cleanScreen:

    li t0, WHITE
    li t1, LED_MATRIX_0_BASE
    la t2, LED_MATRIX_0_SIZE
    add t2, t1, t2

loopLed:

    sw t0, 0(t1)
    addi t1, t1, 4
    bne t1, t2, loopLed
    jr ra

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
    jr ra

printClusters:

    addi sp, sp, -4
    sw ra, 0(sp)
    la s0, points
    lw s1, Npoints
    lw s5, k

    mv t0, s5
    addi t0, t0, -1
    bnez t0, printMultipleCluster
    li a2, RED
    jal printArray
    j printArrayEnd

printMultipleCluster:

    la s2, clusters
    la s3, colors

printClustersLoop:

    beq s1, x0, printArrayEnd
    lw a0, 0(s0)
    lw a1, 4(s0)

    lw t0, 0(s2)
    slli t1, t0, 2
    add t1, s3, t1
    lw a2, 0(t1)            
    jal printPoint

    addi s0, s0, 8
    addi s2, s2, 4
    addi s1, s1, -1
    j printClustersLoop

printArray:

    addi sp, sp, -4
    sw ra, 0(sp)
    
printArrayLoop:

    beq s1, x0, printArrayEnd
    lw a0, 0(s0)
    lw a1, 4(s0)
    jal printPoint

    addi s0, s0, 8
    addi s1, s1, -1
    j printArrayLoop

printArrayEnd:

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

calculateCentroids:

    addi sp, sp, -4         
    sw ra, 0(sp)
    lw s3, Npoints
    lw s5, k
    la s6, centroids
    li t1, 0

    mv t0, s5
    addi t0, t0, -1
    beqz t0, calculateCentroidSingleCluster

calcentroidOuterLoop:

    bge t1, s5, calcCentroidEnd
    la s0, points
    la s4, clusters
    li s1, 0
    li s2, 0
    mv t0, s3
    li t5, 0

calcCentroidInnerLoop:

    beq t0, x0, calcCentroidEndInner
    lw t2, 0(s4)
    bne t2, t1, nextPoint

    lw t3, 0(s0)
    add s1, s1, t3
    lw t4, 4(s0)
    add s2, s2, t4
    addi t5, t5, 1

nextPoint:

    addi s0, s0, 8
    addi s4, s4, 4
    addi t0, t0, -1
    j calcCentroidInnerLoop

calcCentroidEndInner:

    beqz t5, calcCentroidRandomInit
    divu s1, s1, t5
    divu s2, s2, t5
    j calcCentroidStore

calcCentroidRandomInit:

    jal generateRandom
    mv s1, a0
    jal generateRandom
    mv s2, a0

calcCentroidStore:

    sw s1, 0(s6)
    sw s2, 4(s6)

    addi s6, s6, 8
    addi t1, t1, 1
    j calcentroidOuterLoop

calculateCentroidSingleCluster:

    la s0, points
    mv t0, s3
    li s1, 0
    li s2, 0

calcCentroidLoop:

    beq t0, x0, calcCentroidEndSingle
    lw t1, 0(s0)
    add s1, s1, t1
    lw t2, 4(s0)
    add s2, s2, t2 

    addi s0, s0, 8
    addi t0, t0, -1
    j calcCentroidLoop

calcCentroidEndSingle:

    divu s1, s1, s3
    divu s2, s2, s3
    la s0, centroids
    sw s1, 0(s0)
    sw s2, 4(s0)

calcCentroidEnd:

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

printCentroids:

    addi sp, sp, -4
    sw ra, 0(sp)
    la s0, centroids
    lw s1, k
    li a2, BLACK
    jal printArrayLoop
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

mainKmeans:

    addi sp, sp, -4
    sw ra, 0(sp)
    lw s11, L
    jal cleanScreen
    jal initializeCentroids

kMeansLoop:

    beqz s11, kMeansEnd
    jal compareCentroids
    beq a4, x0, kMeansEnd

    jal cleanScreenOptimized
    jal assignCluster
    jal printClusters
    jal printCentroids
    jal copyCentroids
    jal calculateCentroids

    addi s11, s11, -1
    j kMeansLoop

kMeansEnd:

    lw ra, 0(sp)             
    addi sp, sp, 4
    jr ra

initializeCentroids:

    addi sp, sp, -4
    sw ra, 0(sp)
    mv t0, s0
    la t1, centroids

initializeCentroidsLoop:

    beqz t0, initializeCentroidsEnd
    jal generateRandom
    sw a0, 0(t1)
    jal generateRandom
    sw a0, 4(t1)
    addi t1, t1, 8
    addi t0, t0, -1
    j initializeCentroidsLoop

initializeCentroidsEnd:

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

generateRandom:

    li a7, 30
    ecall
    andi a0, a0, 0x1F
    jr ra

manhattanDistance:

    sub t0, a0, a2
    sub t1, a1, a3
    bge t0, x0, continueManhattan
    neg t0, t0

continueManhattan:

    bge t1, x0, 8
    neg t1, t1
    add a0, t0, t1
    jr ra

nearestCluster:

    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    li t6, 0x3E
    li t5, 0
    li t2, 0
    la s2, k
    lw s2, 0(s2)
    la s1, centroids

minDistanceLoop:

    beq t2, s2, minDistanceEnd
    lw a2, 0(s1)
    lw a3, 4(s1)

    jal manhattanDistance
    mv t4, a0
    lw a0, 4(sp)
    blt t4, t6, assignDistance

contMinDistanceLoop:

    addi s1, s1, 8
    addi t2, t2, 1
    j minDistanceLoop

assignDistance:

    mv t6, t4
    mv t5, t2
    j contMinDistanceLoop

minDistanceEnd:

    mv a0, t5
    lw ra, 0(sp)
    addi sp, sp, 8
    jr ra

assignCluster:

    addi sp, sp, -4
    sw ra, 0(sp)
    lw s9, Npoints
    la s8, points
    la s7, clusters

assignClusterLoop:

    beq s9, x0, assignClusterEnd
    lw a0, 0(s8)
    lw a1, 4(s8)
    jal nearestCluster
    sw a0, 0(s7)

    addi s9, s9, -1
    addi s8, s8, 8
    addi s7, s7, 4
    j assignClusterLoop

assignClusterEnd:

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

copyCentroids:

    la t0, centroids
    la s1, oldCentroids
    lw s2, k
    li t1, 0

copyCentroidsLoop:

    beq t1, s2, copyCentroidsEnd
    lw t4, 0(t0)
    sw t4, 0(s1)
    lw t4, 4(t0)
    sw t4, 4(s1)

    addi t0, t0, 8
    addi s1, s1, 8
    addi t1, t1, 1
    j copyCentroidsLoop

copyCentroidsEnd:

    jr ra

compareCentroids:

    la t0, centroids
    la s1, oldCentroids
    lw s2, k
    li t1, 0
    li a4, 1

compareCentroidsLoop:

    beq t1, s2, Equal
    lw t2, 0(t0)
    lw t3, 0(s1)
    bne t2, t3, notEqual

    addi t0, t0, 4
    addi s1, s1, 4
    addi t1, t1, 1
    j compareCentroidsLoop

notEqual:

    jr ra

Equal:

    li a4, 0
    jr ra

cleanScreenOptimized:

    addi sp, sp, -4
    sw ra, 0(sp)
    li a2, WHITE
    la s0, oldCentroids
    lw s1, k
    jal printArray

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
