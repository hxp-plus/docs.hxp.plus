---
tags:
  - Python
---

# 数据类型（dtype）


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Data Types (dtpye) #

* bool
* int
* float
* complex

# Arrays #

数组可以通过列表、元组或函数生成。

## 使用列表生成数组 ##

```python
numpy.array(object, dtype=None, copy=True, order=None, subok=False, ndmin=0)
```

我们只需要关注 `dtype` 参数。它可以是 `int`、`float`、`complex`、`bool`...

**注意：如果不指定 `dtype`，系统会自动选择合适的类型**

示例：

```python
np.array([(1, 2), (3, 4), (5, 6)])
```

## 使用函数生成数组 ##
### np.arange() ###

```

*示例*
``` python
np.arange(3, 7, 0.5, dtype='float32')
```

*输出*

``` python
array([3. , 3.5, 4. , 4.5, 5. , 5.5, 6. , 6.5])
```

``` python
np.arange(number)
```

*示例*
	
``` python
np.arrange(10)
```

*输出*

``` python
array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
```


### np.linspace() ###

``` python
numpy.linspace(start, stop, num=50, endpoint=True, retstep=False, dtype=None)
```

*示例（`endpoint=True`）*

``` python
np.linspace(0, 10, 10, endpoint=True)
```

*输出*

``` python
array([ 0.        ,  1.11111111,  2.22222222,  3.33333333,  4.44444444,
        5.55555556,  6.66666667,  7.77777778,  8.88888889, 10.        ])
```

*示例（`endpoint=False`）*

``` python
np.linspace(0, 10, 10, endpoint=False)
```

*输出*

``` python
array([0., 1., 2., 3., 4., 5., 6., 7., 8., 9.])
```



### np.ones() ###

`np.ones` 用于创建所有元素均为 1 的数组。

``` python
numpy.ones(shape, dtype=None, order='C')

```

*示例*

``` python
np.ones((2, 3))
```

*输出*

``` python
array([[1., 1., 1.],
       [1., 1., 1.]])
```

注意其中的 "2" 称为 "axis 0"，而 "3" 称为 "axis 1"。

在二维数组中，"axis 0" 是列，"axis 1" 是行。

### np.zeros() ###

``` python
numpy.zeros(shape, dtype=None, order='C')
```

*示例*

``` python
np.zeros((3, 2))
```

*输出*

``` python
array([[0., 0.],
       [0., 0.],
       [0., 0.]])
```




### np.eye() ###

`numpy.eye()` 创建一个对角线上为 1、其余位置为 0 的数组。

``` python
numpy.eye(N, M=None, k=0, dtype=<type 'float'>)
```

其中 `k` 表示对角线偏移量。`N` 定义列上的元素数量，`M` 定义行上的元素数量。`M` 的默认值等于 `N`。

见以下 3 个示例。

*示例*

``` python
np.eye(5)
```

*输出*

``` python
array([[1., 0., 0., 0., 0.],
       [0., 1., 0., 0., 0.],
       [0., 0., 1., 0., 0.],
       [0., 0., 0., 1., 0.],
       [0., 0., 0., 0., 1.]])
```

*示例*

``` python
np.eye(5,3)
```

*输出*

``` python
array([[1., 0., 0.],
       [0., 1., 0.],
       [0., 0., 1.],
       [0., 0., 0.],
       [0., 0., 0.]])
```

*示例*

``` python
np.eye(5, 3, -2)
```

*输出*

``` python
array([[0., 0., 0.],
       [0., 0., 0.],
       [1., 0., 0.],
       [0., 1., 0.],
       [0., 0., 1.]])
```




### np.fromfunction() ###

`示例`

``` python
np.fromfunction(lambda a, b: a + b, (5, 4))
```

`输出`

``` python
array([[0., 1., 2., 3.],
       [1., 2., 3., 4.],
       [2., 3., 4., 5.],
       [3., 4., 5., 6.],
       [4., 5., 6., 7.]])
```

注意行列的索引从 0 开始，而不是 1。



## 数组操作 ##
### 设置数组的数据类型 ###

```python
a.astype(int)
```
	
### 获取数组的类型 ###

``` python
a.dtype
```





### 转置数组 ###

``` python
a.T
```

或者使用 `transpose` 函数

``` python
a = np.arange(4).reshape(2, 2)
np.transpose(a)
```

``` python
array([[0, 2],
       [1, 3]])
```

### 获取实部和虚部 ###

``` python
a.real
a.imag
```


### 获取大小、形状和维度 ###

``` python
a.size
a.ndim
a.shape
```


### 重塑和 Resize###

#### 重塑 (Reshape) ####

``` python
np.reshape(newshape, order='C')
```

*示例*

``` python
a=np.arange(10)
a.reshape((5, 2))
```

*输出*

``` python
array([[0, 1],
       [2, 3],
       [4, 5],
       [6, 7],
       [8, 9]])
```

*示例*

``` python
np.arange(10).reshape((5, 2), order='F')
```

*输出*

``` python
array([[0, 5],
       [1, 6],
       [2, 7],
       [3, 8],
       [4, 9]])
```

#### 调整大小 (Resize) ####

``` python
np.resize(a，new_shape)
```

*示例*

``` python
a = np.arange(10)
a.resize(2, 5)
a
```

*输出*

``` python
array([[0, 1, 2, 3, 4],
       [5, 6, 7, 8, 9]])
```

	
### 展平 (Ravel) ###

``` python
np.ravel(array, order='C')
```

*示例*

``` python
np.ravel(a)
```

*输出*

``` python
array([0, 5, 1, 6, 2, 7, 3, 8, 4, 9])
```

*示例*

``` python
np.ravel(a, order='F')
```

*输出*

``` python
array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
```

### 改变轴 ###

``` python
np.moveaxis(a, source, destination)
```

*示例*

``` python
a = np.ones((1, 2, 3))
print(a)
np.moveaxis(a, 0, -1)
```

*输出*

``` python
[[[1. 1. 1.]
  [1. 1. 1.]]]

array([[[1.],
        [1.],
        [1.]],

       [[1.],
        [1.],
        [1.]]])
```

注意在三维数组中，"axis 0" 代表高度，"axis 1" 和 "axis 2" 分别代表 "列" 和 "行"

``` python
np.swapaxis(a, axis1, axis2)
```

*示例*

``` python
a = np.ones((1, 4, 3))
print(a)
np.swapaxes(a, 0, 2)
```

*输出*

``` python
[[[1. 1. 1.]
  [1. 1. 1.]
  [1. 1. 1.]
  [1. 1. 1.]]]

array([[[1.],
        [1.],
        [1.],
        [1.]],

       [[1.],
        [1.],
        [1.],
        [1.]],

       [[1.],
        [1.],
        [1.],
        [1.]]])
```



### 改变维度 ###

``` python
np.atleast_1d()
np.atleast_2d()
np.atleast_3d()
```

*示例*

``` python
print(np.atleast_1d([1, 2, 3]))
print(np.atleast_2d([4, 5, 6]))
print(np.atleast_3d([7, 8, 9]))
```

*输出*

``` python
[1 2 3]
[[4 5 6]]
[[[7]
   [8]
   [9]]]
```


### 拼接 (Concatenate) ###

``` python
np.concatenate((a1, a2, ...), axis=0)
```

*示例*

``` python
a = np.array([[1, 2], [3, 4], [5, 6]])
b = np.array([[7, 8], [9, 10]])
c = np.array([[11, 12]])

np.concatenate((a, b, c), axis=0)
```

*输出*

``` python
array([[ 1,  2],
       [ 3,  4],
       [ 5,  6],
       [ 7,  8],
       [ 9, 10],
       [11, 12]])
```

*示例*

``` python
a = np.array([[1, 2], [3, 4], [5, 6]])
b = np.array([[7, 8, 9]])

np.concatenate((a, b.T), axis=1)
```

*输出*

``` python
array([[1, 2, 7],
       [3, 4, 8],
       [5, 6, 9]])
```


### 拆分 (Split) ###

*示例*

``` python
a = np.arange(10)
np.split(a, 5)
```

*输出*

``` python
[array([0, 1]), array([2, 3]), array([4, 5]), array([6, 7]), array([8, 9])]
```

*示例*

``` python
a = np.arange(10).reshape(2, 5)
np.split(a, 2)
```

*输出*

``` python
[array([[0, 1, 2, 3, 4]]), array([[5, 6, 7, 8, 9]])]
```

### 删除 (Delete) ###

``` python
np.delete(arr，obj，axis)
```

*示例*

``` python
a = np.arange(12).reshape(3, 4)
np.delete(a, 2, 1)
```

*输出*

``` python
array([[ 0,  1,  3],
       [ 4,  5,  7],
       [ 8,  9, 11]])
```

### 插入 (Insert) ###

```python
np.insert(arr，obj，values，axis)
```

*示例*

``` python
a = np.arange(12).reshape(3, 4)
b = np.arange(4)

np.insert(a, 2, b, 0)
```

*输出*

``` python
array([[ 0,  1,  2,  3],
       [ 4,  5,  6,  7],
       [ 0,  1,  2,  3],
       [ 8,  9, 10, 11]])
```

### 追加 (Append) ###

``` python
np.append(arr，values，axis)
```

*示例*

``` python
a = np.arange(6).reshape(2, 3)
b = np.arange(3)

np.append(a, b)
```

*输出*

``` python
array([0, 1, 2, 3, 4, 5, 0, 1, 2])
```



### 翻转 (Flipping) ###

``` python
a = np.arange(16).reshape(4, 4)
print(np.fliplr(a))
print(np.flipud(a))
```

``` python
[[ 3  2  1  0]
 [ 7  6  5  4]
 [11 10  9  8]
 [15 14 13 12]]
[[12 13 14 15]
 [ 8  9 10 11]
 [ 4  5  6  7]
 [ 0  1  2  3]]

Markdown Code

```

## 随机数组 ##

``` python
np.random.rand(2, 5)

np.random.rand(2, 5)

array([[0.09433914, 0.08680661, 0.23040579, 0.71954424, 0.54292341],
       [0.22890897, 0.49553437, 0.01181691, 0.10668025, 0.71153526]])
	   
np.random.randint(2, 5, 10)

array([3, 3, 4, 4, 2, 4, 4, 2, 4, 2])

np.random.random_sample([10])

array([0.80117316, 0.48038627, 0.40861977, 0.22925529, 0.91899056,
       0.70100459, 0.21080387, 0.94939295, 0.374128  , 0.28534828])
```

### 均匀分布 (Uniform Distribution) ###

``` python
np.random.rand(shape)
```

### 正态分布 (Normal Distribution) ###

``` python
np.random.randn(shape)
```

### 学生分布 (Student Distribution) ###

``` python
numpy.random.standard_t(df，size)
``` 

### 其他分布 ###

``` python
    numpy.random.beta(a，b，size)
    numpy.random.binomial(n, p, size)
    numpy.random.chisquare(df，size)
    numpy.random.dirichlet(alpha，size)
    numpy.random.exponential(scale，size)
    numpy.random.f(dfnum，dfden，size)
    numpy.random.gamma(shape，scale，size)
    numpy.random.geometric(p，size)
    numpy.random.gumbel(loc，scale，size)
    numpy.random.hypergeometric(ngood, nbad, nsample, size)
    numpy.random.laplace(loc，scale，size)
    numpy.random.logistic(loc，scale，size)
    numpy.random.lognormal(mean，sigma，size)
    numpy.random.logseries(p，size)
    numpy.random.multinomial(n，pvals，size)
    numpy.random.multivariate_normal(mean, cov, size)
    numpy.random.negative_binomial(n, p, size)
    numpy.random.noncentral_chisquare(df，nonc，size)
    numpy.random.noncentral_f(dfnum, dfden, nonc, size)
    numpy.random.normal(loc，scale，size)
    numpy.random.pareto(a，size)
    numpy.random.poisson(lam，size)    numpy.random.standard_exponential(size)
    numpy.random.standard_gamma(shape，size)
    numpy.random.standard_normal(size)
    numpy.random.standard_t(df，size)
    numpy.random.triangular(left，mode，right，size)
    numpy.random.uniform(low，high，size)
    numpy.random.vonmises(mu，kappa，size)
    numpy.random.wald(mean，scale，size)
    numpy.random.weibull(a，size)
    numpy.random.zipf(a，size)
```
## 函数 ##


---

## 原文（English）

```
---
tags:
  - Python
---

# 数据类型（dtype）


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

* bool
* int
* float
* complex

# Arrays #

Arrays may be generated by lists or tuples, or functions.

## Using lists to generate arrays ##

```python
numpy.array(object, dtype=None, copy=True, order=None, subok=False, ndmin=0)
```

All we need to consider is the `dtype` parameter. It may be `int`, `float`, `complex`, `bool`...

**Note that `dtype` can be selected automatically if you do not specify one**

Example:

```python
np.array([(1, 2), (3, 4), (5, 6)])
```

## Use Functions to generate arrays ##
### np.arange() ###

```

*Example*
``` python
np.arange(3, 7, 0.5, dtype='float32')
```

*Output*

``` python
array([3. , 3.5, 4. , 4.5, 5. , 5.5, 6. , 6.5])
```

``` python
np.arange(number)
```

*Example*
	
``` python
np.arrange(10)
```

*Output*

``` python
array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
```


### np.linspace() ###

``` python
numpy.linspace(start, stop, num=50, endpoint=True, retstep=False, dtype=None)
```

*Example (`endpoint=True`)*

``` python
np.linspace(0, 10, 10, endpoint=True)
```

*Output*

``` python
array([ 0.        ,  1.11111111,  2.22222222,  3.33333333,  4.44444444,
        5.55555556,  6.66666667,  7.77777778,  8.88888889, 10.        ])
```

*Example (`endpoint=False`)*

``` python
np.linspace(0, 10, 10, endpoint=False)
```

*Output*

``` python
array([0., 1., 2., 3., 4., 5., 6., 7., 8., 9.])
```



### np.ones() ###

`np.ones` is used for creating arrays whose elements are all 1.

``` python
numpy.ones(shape, dtype=None, order='C')

```

*Example*

``` python
np.ones((2, 3))
```

*Output*

``` python
array([[1., 1., 1.],
       [1., 1., 1.]])
```

Note that the "2" is called "axis 0", while the "3" is called "axis 1".

In 2 dimension arrays, "axis 0" is the column, "axis 1" is the line.

### np.zeros() ###

``` python
numpy.zeros(shape, dtype=None, order='C')
```

*Example*

``` python
np.zeros((3, 2))
```

*Output*

``` python
array([[0., 0.],
       [0., 0.],
       [0., 0.]])
```




### np.eye() ###

`numpy.eye()` creates an array which has value 1 on its diagonal and 0 on other positions.

``` python
numpy.eye(N, M=None, k=0, dtype=<type 'float'>)
```

Whereas `k` means the offset of diagonal. `N` defines the amount of elements on the column, `M` defines the amount of elements on the row. The default value of `M` is equal to `N`.

See the 3 examples below.

*Example*

``` python
np.eye(5)
```

*Output*

``` python
array([[1., 0., 0., 0., 0.],
       [0., 1., 0., 0., 0.],
       [0., 0., 1., 0., 0.],
       [0., 0., 0., 1., 0.],
       [0., 0., 0., 0., 1.]])
```

*Example*

``` python
np.eye(5,3)
```

*Output*

``` python
array([[1., 0., 0.],
       [0., 1., 0.],
       [0., 0., 1.],
       [0., 0., 0.],
       [0., 0., 0.]])
```

*Example*

``` python
np.eye(5, 3, -2)
```

*Output*

``` python
array([[0., 0., 0.],
       [0., 0., 0.],
       [1., 0., 0.],
       [0., 1., 0.],
       [0., 0., 1.]])
```




### np.fromfunction() ###

`Example`

``` python
np.fromfunction(lambda a, b: a + b, (5, 4))
```

`Output`

``` python
array([[0., 1., 2., 3.],
       [1., 2., 3., 4.],
       [2., 3., 4., 5.],
       [3., 4., 5., 6.],
       [4., 5., 6., 7.]])
```

Notes that the index of column and row counts from 0, not 1.



## Operating with arrays ##
### Set the data type of an array ###

```python
a.astype(int)
```
	
### Get the type of an array ###

``` python
a.dtype
```





### Transpose an array ###

``` python
a.T
```

or you may use the `transpose` function

``` python
a = np.arange(4).reshape(2, 2)
np.transpose(a)
```

``` python
array([[0, 2],
       [1, 3]])
```

### Get the real and imaginary part ###

``` python
a.real
a.imag
```


### Get size, shape and dimension ###

``` python
a.size
a.ndim
a.shape
```


### Reshape and Resize###

#### Reshape ####

``` python
np.reshape(newshape, order='C')
```

*Example*

``` python
a=np.arange(10)
a.reshape((5, 2))
```

*Output*

``` python
array([[0, 1],
       [2, 3],
       [4, 5],
       [6, 7],
       [8, 9]])
```

*Example*

``` python
np.arange(10).reshape((5, 2), order='F')
```

*Output*

``` python
array([[0, 5],
       [1, 6],
       [2, 7],
       [3, 8],
       [4, 9]])
```

#### Resize ####

``` python
np.resize(a，new_shape)
```

*Example*

``` python
a = np.arange(10)
a.resize(2, 5)
a
```

*Output*

``` python
array([[0, 1, 2, 3, 4],
       [5, 6, 7, 8, 9]])
```

	
### Ravel ###

``` python
np.ravel(array, order='C')
```

*Example*

``` python
np.ravel(a)
```

*Output*

``` python
array([0, 5, 1, 6, 2, 7, 3, 8, 4, 9])
```

*Example*

``` python
np.ravel(a, order='F')
```

*Output*

``` python
array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
```

### Change axis ###

``` python
np.moveaxis(a, source, destination)
```

*Example*

``` python
a = np.ones((1, 2, 3))
print(a)
np.moveaxis(a, 0, -1)
```

*Output*

``` python
[[[1. 1. 1.]
  [1. 1. 1.]]]

array([[[1.],
        [1.],
        [1.]],

       [[1.],
        [1.],
        [1.]]])
```

Note that in a three dimension array, "axis 0" represents the height, "axis 1" and "axis 2" represents of "column" and "row"

``` python
np.swapaxis(a, axis1, axis2)
```

*Example*

``` python
a = np.ones((1, 4, 3))
print(a)
np.swapaxes(a, 0, 2)
```

*Output*

``` python
[[[1. 1. 1.]
  [1. 1. 1.]
  [1. 1. 1.]
  [1. 1. 1.]]]

array([[[1.],
        [1.],
        [1.],
        [1.]],

       [[1.],
        [1.],
        [1.],
        [1.]],

       [[1.],
        [1.],
        [1.],
        [1.]]])
```



### Change the dimension ###

``` python
np.atleast_1d()
np.atleast_2d()
np.atleast_3d()
```

*Example*

``` python
print(np.atleast_1d([1, 2, 3]))
print(np.atleast_2d([4, 5, 6]))
print(np.atleast_3d([7, 8, 9]))
```

*Output*

``` python
[1 2 3]
[[4 5 6]]
[[[7]
   [8]
   [9]]]
```


### Concatenate ###

``` python
np.concatenate((a1, a2, ...), axis=0)
```

*Example*

``` python
a = np.array([[1, 2], [3, 4], [5, 6]])
b = np.array([[7, 8], [9, 10]])
c = np.array([[11, 12]])

np.concatenate((a, b, c), axis=0)
```

*Output*

``` python
array([[ 1,  2],
       [ 3,  4],
       [ 5,  6],
       [ 7,  8],
       [ 9, 10],
       [11, 12]])
```

*Example*

``` python
a = np.array([[1, 2], [3, 4], [5, 6]])
b = np.array([[7, 8, 9]])

np.concatenate((a, b.T), axis=1)
```

*Output*

``` python
array([[1, 2, 7],
       [3, 4, 8],
       [5, 6, 9]])
```


### Split ###

*Example*

``` python
a = np.arange(10)
np.split(a, 5)
```

*Output*

``` python
[array([0, 1]), array([2, 3]), array([4, 5]), array([6, 7]), array([8, 9])]
```

*Example*

``` python
a = np.arange(10).reshape(2, 5)
np.split(a, 2)
```

*Output*

``` python
[array([[0, 1, 2, 3, 4]]), array([[5, 6, 7, 8, 9]])]
```

### Delete ###

``` python
np.delete(arr，obj，axis)
```

*Example*

``` python
a = np.arange(12).reshape(3, 4)
np.delete(a, 2, 1)
```

*Output*

``` python
array([[ 0,  1,  3],
       [ 4,  5,  7],
       [ 8,  9, 11]])
```

### Insert ###

```python
np.insert(arr，obj，values，axis)
```

*Example*

``` python
a = np.arange(12).reshape(3, 4)
b = np.arange(4)

np.insert(a, 2, b, 0)
```

*Output*

``` python
array([[ 0,  1,  2,  3],
       [ 4,  5,  6,  7],
       [ 0,  1,  2,  3],
       [ 8,  9, 10, 11]])
```

### Append ###

``` python
np.append(arr，values，axis)
```

*Example*

``` python
a = np.arange(6).reshape(2, 3)
b = np.arange(3)

np.append(a, b)
```

*Output*

``` python
array([0, 1, 2, 3, 4, 5, 0, 1, 2])
```



### Flipping ###

``` python
a = np.arange(16).reshape(4, 4)
print(np.fliplr(a))
print(np.flipud(a))
```

``` python
[[ 3  2  1  0]
 [ 7  6  5  4]
 [11 10  9  8]
 [15 14 13 12]]
[[12 13 14 15]
 [ 8  9 10 11]
 [ 4  5  6  7]
 [ 0  1  2  3]]

Markdown Code

```

## Random arrays ##

``` python
np.random.rand(2, 5)

np.random.rand(2, 5)

array([[0.09433914, 0.08680661, 0.23040579, 0.71954424, 0.54292341],
       [0.22890897, 0.49553437, 0.01181691, 0.10668025, 0.71153526]])
	   
np.random.randint(2, 5, 10)

array([3, 3, 4, 4, 2, 4, 4, 2, 4, 2])

np.random.random_sample([10])

array([0.80117316, 0.48038627, 0.40861977, 0.22925529, 0.91899056,
       0.70100459, 0.21080387, 0.94939295, 0.374128  , 0.28534828])
```

### Uniform Distribution ###

``` python
np.random.rand(shape)
```

### Normal Distribution ###

``` python
np.random.randn(shape)
```

### Student Distribution ###

``` python
numpy.random.standard_t(df，size)
``` 

### Other Distributions ###

``` python
    numpy.random.beta(a，b，size)
    numpy.random.binomial(n, p, size)
    numpy.random.chisquare(df，size)
    numpy.random.dirichlet(alpha，size)
    numpy.random.exponential(scale，size)
    numpy.random.f(dfnum，dfden，size)
    numpy.random.gamma(shape，scale，size)
    numpy.random.geometric(p，size)
    numpy.random.gumbel(loc，scale，size)
    numpy.random.hypergeometric(ngood, nbad, nsample, size)
    numpy.random.laplace(loc，scale，size)
    numpy.random.logistic(loc，scale，size)
    numpy.random.lognormal(mean，sigma，size)
    numpy.random.logseries(p，size)
    numpy.random.multinomial(n，pvals，size)
    numpy.random.multivariate_normal(mean, cov, size)
    numpy.random.negative_binomial(n, p, size)
    numpy.random.noncentral_chisquare(df，nonc，size)
    numpy.random.noncentral_f(dfnum, dfden, nonc, size)
    numpy.random.normal(loc，scale，size)
    numpy.random.pareto(a，size)
    numpy.random.poisson(lam，size)    numpy.random.standard_exponential(size)
    numpy.random.standard_gamma(shape，size)
    numpy.random.standard_normal(size)
    numpy.random.standard_t(df，size)
    numpy.random.triangular(left，mode，right，size)
    numpy.random.uniform(low，high，size)
    numpy.random.vonmises(mu，kappa，size)
    numpy.random.wald(mean，scale，size)
    numpy.random.weibull(a，size)
    numpy.random.zipf(a，size)
```
## Functions ##
```