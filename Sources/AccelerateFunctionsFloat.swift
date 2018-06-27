//
//  AccelerateFunctionsFloat.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

//VECTOR OPERATIONS//

/// Add a scalar to a every element of a vector
public func vectorAddition<A: UnsafeBuffer>(vector: A, add: Float) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var sum = [Float](repeating: 0, count: vector.count)

    var addScalar = add
    vector.performWithUnsafeBufferPointer { (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_vsadd(pointer.baseAddress!, 1, &addScalar, &sum, 1, UInt(vector.count))
    }
    return sum
}

/// Add two vectors of same size
/// - Returns: The sum vector
public func vectorAddition<A: UnsafeBuffer>(vectorA: A, vectorB: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var sum = [Float](repeating: 0, count: vectorA.count)
    vectorA.performWithUnsafeBufferPointer { (pointerA: UnsafeBufferPointer<Float>) -> Void in
        vectorB.performWithUnsafeBufferPointer { (pointerB: UnsafeBufferPointer<Float>) -> Void in
            vDSP_vadd(pointerA.baseAddress!, 1, pointerB.baseAddress!, 1, &sum, 1, UInt(vectorA.count))
        }
    }
    return sum
}


/// Substract `vectorB` from `vectorA` of the same size
/// - Returns: The difference vector
public func vectorSubtraction<A: UnsafeBuffer>(_ vectorA: A, vectorB: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
//    var difference = [Float](count: vectorA.count, repeatedValue: 0)
//    vectorA.performWithUnsafeBufferPointer { (pointerA: UnsafeBufferPointer<Float>) -> Void in
//        vectorB.performWithUnsafeBufferPointer { (pointerB: UnsafeBufferPointer<Float>) -> Void in
//            vDSP_vsub(pointerB.baseAddress, 1, pointerA.baseAddress, 1, &difference, 1, UInt(vectorA.count))
//        }
//    }

    var difference = Array(vectorA)
    vectorB.performWithUnsafeBufferPointer { (pointerB: UnsafeBufferPointer<Float>) -> Void in
        cblas_saxpy(Int32(vectorA.count), -1.0, pointerB.baseAddress, 1, &difference, 1)
    }
    return difference
}

/// Multiply every element of a vector with a scalar factor
public func vectorMultiplication<A: UnsafeBuffer>(_ vector: A, factor: Float) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var product = [Float](repeating: 0, count: vector.count)
    var factorScalar = factor
    vector.performWithUnsafeBufferPointer { (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_vsmul(pointer.baseAddress!, 1, &factorScalar, &product, 1, UInt(vector.count))
    }
    return product
}

/// Multiply two vectors of same size element wise
/// - Returns: The product vector
public func vectorElementWiseMultiplication<A: UnsafeBuffer>(_ vectorA: A, vectorB: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var product = [Float](repeating: 0, count: vectorA.count)
    vectorA.performWithUnsafeBufferPointer { (pointerA: UnsafeBufferPointer<Float>) -> Void in
        vectorB.performWithUnsafeBufferPointer { (pointerB: UnsafeBufferPointer<Float>) -> Void in
            vDSP_vmul(pointerA.baseAddress!, 1, pointerB.baseAddress!, 1, &product, 1, UInt(vectorA.count))
        }
    }
    return product
}

/// Divide `vectorA` by `vectorB` element wise
/// - Returns: The difference vector
public func vectorDivision<A: UnsafeBuffer>(_ vectorA: A, vectorB: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var quotient = [Float](repeating: 0, count: vectorA.count)
    vectorA.performWithUnsafeBufferPointer { (pointerA: UnsafeBufferPointer<Float>) -> Void in
        vectorB.performWithUnsafeBufferPointer { (pointerB: UnsafeBufferPointer<Float>) -> Void in
            vDSP_vdiv(pointerB.baseAddress!, 1, pointerA.baseAddress!, 1, &quotient, 1, UInt(vectorA.count))
        }
    }
    return quotient
}

/// Divide a scalar by every element of a vector
public func vectorDivision<A: UnsafeBuffer>(numerator: Float, vector: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var quotient = [Float](repeating: 0, count: vector.count)
    var numScalar = numerator
    vector.performWithUnsafeBufferPointer { (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_svdiv(&numScalar, pointer.baseAddress!, 1, &quotient, 1, UInt(vector.count))
    }
    return quotient
}

/// Calculate the negative of every element of a vector
public func vectorNegation<A: UnsafeBuffer>(_ vector: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var neg = [Float](repeating: 0, count: vector.count)
    vector.performWithUnsafeBufferPointer{ (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_vneg(pointer.baseAddress!, 1, &neg, 1, UInt(vector.count))
    }
    return neg
}

/// Calculate the sum of all elements in the vector
public func vectorSummation<A: UnsafeBuffer>(_ vector: A) -> Float where A.Iterator.Element == Float, A.Index == Int {
    var sum: Float = 0
    vector.performWithUnsafeBufferPointer{ (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_sve(pointer.baseAddress!, 1, &sum, UInt(vector.count))
    }
    return sum
}

/// Square every element of the vector
public func vectorSquaring<A: UnsafeBuffer>(_ vector: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var squares = [Float](repeating: 0, count: vector.count)
    vector.performWithUnsafeBufferPointer{ (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_vsq(pointer.baseAddress!, 1, &squares, 1, UInt(vector.count))
    }
    return squares
}

/// Calculate the exponential (e^v[n]) of every element of the vector
public func vectorExponential<A: UnsafeBuffer>(_ vector: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var exp = [Float](repeating: 0, count: vector.count)
    var count = Int32(vector.count)
    vector.performWithUnsafeBufferPointer{ (pointer: UnsafeBufferPointer<Float>) -> Void in
        vvexpf(&exp, pointer.baseAddress!, &count)
    }
    return exp
}

/// Calculate the (natural) logarithm of every element of the vector
public func vectorLogarithm<A: UnsafeBuffer>(_ vector: A) -> [Float] where A.Iterator.Element == Float, A.Index == Int {
    var log = [Float](repeating: 0, count: vector.count)
    var count = Int32(vector.count)
    vector.performWithUnsafeBufferPointer{ (pointer: UnsafeBufferPointer<Float>) -> Void in
        vvlogf(&log, pointer.baseAddress!, &count)
    }
    return log
}

/// Normalize the elements of the given vector
/// - Returns:
/// `normalizedVector` with mean 0 and standard deviation 1, <br>
/// `mean` of the input vector, <br>
/// `standardDeviation` of the input vector
public func vectorNormalization<A: UnsafeBuffer>(_ vector: A) -> (normalizedVector: [Float], mean: Float, standardDeviation: Float) where A.Iterator.Element == Float, A.Index == Int {
    var norm = [Float](repeating: 0, count: vector.count)
    var mean: Float = 0
    var deviation: Float = 0
    vector.performWithUnsafeBufferPointer { (pointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_normalize(pointer.baseAddress!, 1, &norm, 1, &mean, &deviation, UInt(vector.count))
    }
    if(mean == 0 && deviation == 0) {
        norm = [Float](repeating: 0, count: vector.count)
    }
    return (norm, mean, deviation)
}




//MATRIX OPERATIONS//
//All functions use row-major matrices

public struct MatrixSize {
    public var rows: Int
    public var columns: Int
    public var transpose: MatrixSize {
        get {
            return MatrixSize(rows: columns, columns: rows)
        }
    }
    public var elementCount: Int {
        get {
            return rows*columns
        }
    }

    public init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
    }
    public init(_ size: [Int]) {
        self.rows = size[0]
        self.columns = size[1]
    }
}

/// Matrix transpose
public func matrixTranspose<A: UnsafeBuffer>(_ matrix: A, size: MatrixSize) -> [Float] where A.Iterator.Element == Float {
    var result = [Float](repeating: 0, count: size.columns*size.rows)
    matrix.performWithUnsafeBufferPointer { (matrixPointer: UnsafeBufferPointer<Float>) -> Void in
        vDSP_mtrans(matrixPointer.baseAddress!, 1, &result, 1, UInt(size.columns), UInt(size.rows))
    }
    return result
}

/// Check if the dimensions are compatible for matrix multiplication
/// - Returns: The effective matrixSizes after transposition
internal func matrixMultiplyDimensions(sizeA: MatrixSize, transposeA: Bool, sizeB: MatrixSize, transposeB: Bool) -> (sizeA: MatrixSize, sizeB: MatrixSize) {

    if (transposeA && transposeB) {
        assert(sizeA.rows == sizeB.columns, "Cannot multiply matrices of size \(sizeA.columns)x\(sizeA.rows) and \(sizeB.columns)x\(sizeB.rows)")
        return (sizeA.transpose, sizeB.transpose)
    } else if (transposeA) {
        assert(sizeA.rows == sizeB.rows, "Cannot multiply matrices of size \(sizeA.columns)x\(sizeA.rows) and \(sizeB.rows)x\(sizeB.columns)")
        return (sizeA.transpose, sizeB)
    } else if (transposeB) {
        assert(sizeA.columns == sizeB.columns, "Cannot multiply matrices of size \(sizeA.rows)x\(sizeA.columns) and \(sizeB.columns)x\(sizeB.rows)")
        return (sizeA, sizeB.transpose)
    } else {
        assert(sizeA.columns == sizeB.rows, "Cannot multiply matrices of size \(sizeA.rows)x\(sizeA.columns) and \(sizeB.rows)x\(sizeB.columns)")
        return (sizeA, sizeB)
    }
}

public extension CBLAS_TRANSPOSE {
    init(isTranspose: Bool = false, isConjugate: Bool = false) {
        switch isTranspose {
        case true:
            switch isConjugate {
            case true:
                self.init(rawValue: 113)
            default:
                self.init(rawValue: 112)
            }
        default:
            self.init(rawValue: 111)
        }
    }
}

/// Matrix multiplication
/// - Parameter matrixA: Left matrix
/// - Parameter sizeA: The size of `matrixA`
/// - Parameter transposeA: `matrixA` should be transposed before the multiplication. Default: `false`
/// - Parameter matrixB: Right matrix
/// - Parameter sizeB: The size of `matrixB`
/// - Parameter transposeB: `matrixB` should be transposed before the multiplication. Default: `false`
/// - Returns: The product matrix
public func matrixMultiplication<A: UnsafeBuffer>(matrixA: A, sizeA: MatrixSize, transposeA: Bool = false, matrixB: A, sizeB: MatrixSize, transposeB: Bool = false, useBLAS: Bool = false) -> [Float] where A.Iterator.Element == Float {

    //vDSP seems to have better performance, at least for matrices with 10,000,000 elements or fewer.
    let (newSizeA, newSizeB) = matrixMultiplyDimensions(sizeA: sizeA, transposeA: transposeA, sizeB: sizeB, transposeB: transposeB)
    //print("matrix multiplication: (\(newSizeA.rows) x \(newSizeA.columns)) * (\(newSizeB.rows) x \(newSizeB.columns))")

    var matrixC = [Float](repeating: 0, count: newSizeA.rows * newSizeB.columns)

    matrixA.performWithUnsafeBufferPointer { (matrixABuffer: UnsafeBufferPointer<Float>) -> Void in
        matrixB.performWithUnsafeBufferPointer { (matrixBBuffer: UnsafeBufferPointer<Float>) -> Void in
            let matrixAPointer = matrixABuffer.baseAddress
            let matrixBPointer = matrixBBuffer.baseAddress
            if useBLAS {
                cblas_sgemm(CblasRowMajor, CBLAS_TRANSPOSE(isTranspose: transposeA), CBLAS_TRANSPOSE(isTranspose: transposeB), Int32(newSizeA.rows), Int32(newSizeB.columns), Int32(newSizeA.columns), 1, matrixAPointer, Int32(sizeA.columns), matrixBPointer, Int32(sizeB.columns), 1, &matrixC, Int32(newSizeB.columns))

            } else {
                if (transposeA && transposeB) {
                    vDSP_mmul(matrixTranspose(matrixA, size: sizeA), 1, matrixTranspose(matrixB, size: sizeB), 1, &matrixC, 1, UInt(newSizeA.rows), UInt(newSizeB.columns), UInt(newSizeA.columns))
                } else if transposeA {
                    vDSP_mmul(matrixTranspose(matrixA, size: sizeA), 1, matrixBPointer!, 1, &matrixC, 1, UInt(newSizeA.rows), UInt(newSizeB.columns), UInt(newSizeA.columns))
                } else if transposeB {
                    vDSP_mmul(matrixAPointer!, 1, matrixTranspose(matrixB, size: sizeB), 1, &matrixC, 1, UInt(newSizeA.rows), UInt(newSizeB.columns), UInt(newSizeA.columns))
                } else {
                    vDSP_mmul(matrixAPointer!, 1, matrixBPointer!, 1, &matrixC, 1, UInt(newSizeA.rows), UInt(newSizeB.columns), UInt(newSizeA.columns))
                }
            }
        }
    }

    return matrixC
}

/// Matrix multiplication where one matrix is diagonal
/// - Parameter matrix: The full matrix
/// - Parameter size: The size of `matrix`
/// - Parameter diagonals: The diagonal matrix in form of a vector consisting of the diagonal values
/// - Parameter diagonalMatrixSize: The size of the diagonal matrix. Does not have to be square.
/// - Parameter matrixFirst: If true, the full matrix is left and the diagonal matrix is right, else the diagonal matrix is left and the full matrix is right.
/// - Returns: The product matrix
public func diagonalMatrixMultiplication<A: UnsafeBuffer>(_ matrix: A, size: MatrixSize, diagonals: A, diagonalMatrixSize: MatrixSize, matrixFirst: Bool) -> [Float] where A.Iterator.Element == Float, A.SubSequence.Iterator.Element == Float, A.Index == Int {

    var product: [Float] = []


    if(matrixFirst) { // calculate M * D
        //        assert(diagonals.count <= size.columns, "Cannot multiply \(diagonals.count) diagonal values with a \(size.rows) x \(size.columns) matrix")
        let diagonalValues = Array(diagonals) + [Float](repeating: 0, count: diagonalMatrixSize.columns - diagonals.count)

        let productSize = MatrixSize(rows: size.rows, columns: diagonalMatrixSize.columns)
        product.reserveCapacity(productSize.elementCount)
        let rangeLength = min(size.columns, diagonals.count)
        let paddingZeros = [Float](repeating: 0, count: diagonalMatrixSize.columns - rangeLength)

        for r in 0..<size.rows {
            let thisRange = CountableRange(start: r*size.columns, distance: rangeLength)
            let slice = Array(matrix[thisRange]) + paddingZeros
            let result = vectorElementWiseMultiplication(slice, vectorB: diagonalValues)
            product.append(contentsOf: result)
        }
    } else { // calculate D * M
        //        assert(diagonals.count <= size.rows, "Cannot multiply a \(size.rows) x \(size.columns) matrix with \(diagonals.count) diagonal values")
        let diagonalValues = Array(diagonals) + [Float](repeating: 0, count: diagonalMatrixSize.rows - diagonals.count)

        let productSize = MatrixSize(rows: diagonalMatrixSize.rows, columns: size.columns)
        product.reserveCapacity(productSize.elementCount)

        for d in 0..<diagonalValues.count {
            let thisRange = CountableRange(start: d*size.columns, distance: size.columns)
            let slice = Array(matrix[thisRange])
            let result = vectorMultiplication(slice, factor: diagonals[d])
            product.append(contentsOf: result)
        }
    }

    return product
}

/// Eigendecomposition of a real symmetric matrix
/// - Returns:
/// `eigenvalues:` The eigenvalues of the matrix in descending magnitude <br>
/// `eigenvectors:` The corresponding eigenvectors as row vectors in a matrix
public func eigendecomposition<A: UnsafeBuffer>(_ matrix: A, size: MatrixSize) -> (eigenvalues: [Float], eigenvectors: [Float]) where A.Iterator.Element == Float {
    assert(size.rows == size.columns, "eigendecomposition not possible for matrix of dimension \(size.rows)x\(size.columns)")
    print("eigendecomposition of a \(size.rows) x \(size.columns) matrix")

    var inMatrix = matrixTranspose(matrix, size: size) //LAPACK uses Fortran style column-major matrices, hence the transpose
    var jobvl = "N".charValue //options for left eigenvectors, "N" means the left eigenvectors are not computed
    var jobvr = "V".charValue //options for left eigenvectors, "V" means the left eigenvectors are computed
    var n = Int32(size.rows)
    var wr = [Float](repeating: 0, count: Int(n)) //eigenvalues (real part)
    var wi = [Float](repeating: 0, count: Int(n)) //eigenvalues (imaginary part)
    var vl = [Float]() //(left eigenvectors are not computed)
    var vr = [Float](repeating: 0, count: Int(n*n)) //right eigenvectors
    var lwork = 40*n
    var workspace = [__CLPK_real](repeating: 0, count: Int(lwork))
    var info: Int32 = 0

    //eigendecomposition
    //documentation: http://www.netlib.org/lapack/explore-html/d3/dfb/group__real_g_eeigen.html#ga104525b749278774f7b7f57195aa6798
    sgeev_(&jobvl, &jobvr, &n, &inMatrix, &n, &wr, &wi, &vl, &n, &vr, &n, &workspace, &lwork, &info)
    assert(info < 1, "cannot inverse a singular matrix")
    assert(info == 0, "eigenvalues have not converged")
    if(Int(lwork) < Int(workspace[0])) {
        print("optimal lwork argument: \(workspace[0]), given lwork: \(lwork)")
    }


    let newOrder = wr.combineWith(Array(0..<Int(n)), combineFunction: {($0, $1)}).sorted(by: {abs($0.0) > abs($1.0)})
    let sortedEigenvectors = newOrder.map({vr[CountableRange(start: $0.1*Int(n), distance: Int(n))]}).flatMap({Array($0)})

    return (newOrder.map({$0.0}), sortedEigenvectors)
}

/// Singular value decomposition of a matrix
/// - Returns:
/// `uMatrix`: The left singular vectors as row vectors in a matrix
/// `singularValues`: Vector consisting of all singular values
/// `vMatrix`: The right singular vectors as row vectors in a matrix
public func singularValueDecomposition<A: UnsafeBuffer>(_ matrix: A, size: MatrixSize) -> (uMatrix: [Float], singularValues: [Float], vMatrix: [Float]) where A.Iterator.Element == Float {

    var inMatrix = matrixTranspose(matrix, size: size) //LAPACK uses Fortran style column-major matrices, hence the transpose
    var jobu = "A".charValue //options for left singular vectors, "A" means the full m x m matrix is returned in u
    var jobvt = "A".charValue //options for right singular vectors, "A" means the full transposed n x n matrix is returned in vt
    var m = Int32(size.rows)
    var n = Int32(size.columns)
    var s = [Float](repeating: 0, count: Int(min(m, n))) //the singular values
    var u = [Float](repeating: 0, count: Int(m*m)) //matrix containing the left singular vectors
    var vt = [Float](repeating: 0, count: Int(n*n)) //transposed matrix containing the left singular vectors
    var info: Int32 = 0

    //calculate size for workspace
    let lwork1 = 3*min(m, n) + max(m, n) + 10
    let lwork2 = 5*min(m, n)-4 + 10
    var lwork = Int32(max(lwork1, lwork2))
    var workspace = [__CLPK_real](repeating: 0, count: Int(lwork))

    //SVD
    //documentation: http://www.netlib.org/lapack/explore-html/d4/dca/group__real_g_esing.html#gaf03d06284b1bfabd3d6c0f6955960533
    //lda / leading dimension means the memory space between the vectors of the second dimension. Usually just the number of rows
    sgesvd_(&jobu, &jobvt, &m, &n, &inMatrix, &m, &s, &u, &m, &vt, &n, &workspace, &lwork, &info)

    assert(info < 1, "\(info) superdiagonals did not converge to zero in singular value decomposition")
    assert(info == 0, "error in \(-info)th argument")

    return (matrixTranspose(u, size: MatrixSize(rows: size.rows, columns: size.rows)), s, vt)
}

/// Inverse of a square matrix
public func matrixInverse<A: UnsafeBuffer>(_ matrix: A, size: MatrixSize) -> [Float] where A.Iterator.Element == Float {

    assert(size.rows == size.columns, "inverse not possible for matrix of dimension \(size.rows)x\(size.columns)")
    var inMatrix = Array(matrix)

    var n = Int32(size.rows)
    var pivots = [Int32](repeating: 0, count: size.rows)
    var info: Int32 = 0

    //LU factorization
    //documentation: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational.html#ga8d99c11b94db3d5eac75cac46a0f2e17
    sgetrf_(&n, &n, &inMatrix, &n, &pivots, &info)
    assert(info < 1, "cannot inverse a singular matrix")
    assert(info == 0, "error in \(info)th argument")

    var workspace: [__CLPK_real]
    var lwork : Int32
    if(n < 60) {
        workspace = [__CLPK_real](repeating: 0, count: Int(n))
        lwork = Int32(n)
    } else {
        workspace = [__CLPK_real](repeating: 0, count: Int(n)*128)
        lwork = Int32(n*128)
    }
    info = 0

    //Inverse of a LU factorization
    //documentation: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational.html#ga1af62182327d0be67b1717db399d7d83
    sgetri_(&n, &inMatrix, &n, &pivots, &workspace, &lwork, &info)
    assert(info < 1, "cannot inverse a singular matrix")
    assert(info == 0, "error in \(info)th argument")
    //print("optimal lwork argument: \(workspace[0])")

    return inMatrix
}

/// Moore-Penrose pseudoinverse of matrix
/// - Parameter matrix: The matrix that will be inversed
/// - Parameter size: The size of this matrix. Does not have to be square
/// - Returns: The pseudoinverse matrix of with the transposed size of the input matrix.
public func pseudoInverse<A: UnsafeBuffer>(_ matrix: A, size: MatrixSize) -> [Float] where A.Iterator.Element == Float {
    //matrix: m x n
    //u: m x m, s: m x n, v: n x n
    let (u, s, v) = singularValueDecomposition(matrix, size: size)
    let uSize = MatrixSize(rows: size.rows, columns: size.rows)
    let vSize = MatrixSize(rows: size.columns, columns: size.columns)

    //matrixInverse = v * sInverse * u_T
    let sInverse = s.map({($0 != 0) ? 1/$0 : 0}) // n x m
    let vsInverseProduct = diagonalMatrixMultiplication(v, size: vSize, diagonals: sInverse, diagonalMatrixSize: size.transpose, matrixFirst: true) // n x m
    let inverse = matrixMultiplication(matrixA: vsInverseProduct, sizeA: size.transpose, matrixB: u, sizeB: uSize, transposeB: true)

    return inverse
}

public func solveLinearEquationSystem<A: UnsafeBuffer>(_ factorMatrix: A, factorMatrixSize: MatrixSize, results: A, resultsSize: MatrixSize) -> [Float] where A.Iterator.Element == Float {

    assert(factorMatrixSize.columns == factorMatrixSize.rows, "factor matrix is not square: \(factorMatrixSize)")
    assert(factorMatrixSize.columns == resultsSize.rows, "resultsSize \(resultsSize.rows) is not compatible with factor matrix size \(factorMatrixSize.columns)")

    var a = matrixTranspose(factorMatrix, size: factorMatrixSize)
    var b = matrixTranspose(results, size: resultsSize)
    var n = Int32(factorMatrixSize.columns)
    var lda = n
    var ldb = n
    var nrhs = Int32(resultsSize.columns)
    var ipiv = [Int32](repeating: 0, count: Int(n))
    var info: Int32 = 0

    let r = sgesv_(&n, &nrhs, &a, &lda, &ipiv, &b, &ldb, &info)

    return b
}

