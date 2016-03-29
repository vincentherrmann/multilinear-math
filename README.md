# multilinear-math
Swift library for multidimensional data and tensor operations on OS X

## Tensor reading, writing, slicing
Create data tensor: <br>
```var a = Tensor<Float>(modeSizes: [3, 3, 3], repeatedValue: 0)``` <br><br>

Read a single value: <br>
```let b: Float = a[1, 2, 0]``` <br>
Write a single value: <br>
```a[2, 0, 1] = 3.14``` <br><br>

Slice a tensor: <br>
```let c: Tensor<Float> = a[1..<3, all, [0]]``` <br>
Write multiple values: <br>
```a[1...1, [0, 2], all] = Tensor<Float>(modeSizes: [2, 3], values: [1, 2, 3, 4, 5, 6])``` <br>
*modes of size 1 will be trimmed*

## Einstein notation
Modes with same symbolic index will be summed over. Simple matrix multiplication: <br>
```var m = Tensor<Float>(modeSizes: [4, 6], repeatedValue: 1)``` <br> 
```var n = Tensor<Float>(modeSizes: [6, 5], repeatedValue: 2)``` <br>
```let matrixProduct = m[.i, .j] * n[.j, .k]```

## Multilinear subspace learning
Extended PCA algorithms to work with tensors with arbitrary mode count
 - multilinear principal component analysis (MPCA)
 - uncorrelated multilinear principal component analysis (UMPCA) <br>
*(Lu, Plataniotis, Venetsanopoulos)*


