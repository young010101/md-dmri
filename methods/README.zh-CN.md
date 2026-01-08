# MD-dMRI 方法总览（中文）

在 MD-dMRI 框架中目前实现了三大类方法：

- [扩散张量分布](#扩散张量分布)
- [扩散交换](#扩散交换)
- [扩散与非相干流动](#扩散与非相干流动)

下面对这些方法做简要说明，更详细内容可参考两篇综述<sup>1,2</sup>以及各方法的原始论文。为便于已有常规 dMRI 经验的非专业读者理解，我们先给出直观的解释，再讨论较为严格的数学与物理描述。本文假设读者熟悉标准 dMRI 术语，如扩散张量、扩散各向异性、峰度、取向分布函数（ODF）与体素内非相干运动（IVIM），以及常用缩写 DTI、MD、FA、DKI 等<sup>3-6</sup>。

随后还提供一些[Matlab 代码实现细节](#实现细节)以生成 MD-dMRI 参数图。

## 扩散张量分布

组织的微观几何会体现在水分子扩散张量的大小、形状与取向上。常规方法在毫米级体素内对所有微环境的扩散张量做平均，因此在异质性显著的人脑组织中会产生歧义。我们的 MD-dMRI 方法能够区分微观扩散张量的大小、形状与取向效应，并以明确的统计量刻画扩散张量分布。这些统计量与组织性质（如平均细胞形状、细胞密度的变化）之间具有简单直观的联系。

扩散张量分布（DTD）模型假设体素内水分子可划分为多个组，每个组呈各向异性的高斯扩散，用一个微观扩散张量 **D** 表征。该张量可表示为 3×3 矩阵，并以椭球可视化，其半轴长度与方向由特征值与特征向量决定。通俗地说，一个扩散张量可由大小、形状与取向描述，这些属性由化学组成与微米尺度孔隙几何决定。相同术语也可用于描述组织中的细胞，但下文将专指张量。张量与细胞微观属性的关系在 dMRI 文献中已有详细研究。

![Image](DTD_2Spheres2Sticks.png)

上图示意了一个异质体素作为多个微观扩散张量的集合，每个张量代表一组水分子。常规 DTI/DKI 输出的参数会将大小、形状、取向信息混合在一起，而 DTD 模型旨在给出“干净”的大小、形状、取向量，便于直观看图得出结论。图中可见四类张量：两个大小不同的球状（各向同性）张量，以及两个大小与形状近似但取向不同的近线性张量。DTD 模型的最完整描述是枚举每个微观张量的大小、形状、取向与分数；或者给出连续概率分布 _P_(**D**)。完全描述虽具挑战，但在足够的扫描时间下仍可实现。更常用做法是放弃分离各成分，而关注刻画大小、形状与取向的均值与方差等标量量。下图示例说明了该思路的实用性，这三个体素在常规 DTI 下不可区分——体素平均张量 <**D**> 及其派生参数 MD、FA 完全相同。

![Image](DTD_3Examples.png)

左图由取向相同的近线性（长棒状）张量组成；中图含三个不同取向的近线性张量；右图更复杂，包含大小不同的两类球状张量与一个中等大小的线性张量。要区分这三种情况，至少需要三个标量量，例如大小方差、平均形状与取向有序度。三者的平均大小相同；尽管不那么显然，左图与右图的平均形状与有序度相同；左图与中图则可通过平均形状与有序度的差异区分；右图的独特之处在于同时具有大小与形状的方差。

### 扩散张量的参数化

上文用大小、形状、取向描述扩散张量，但尚未给出严格定义。一般扩散张量 **D** 含 6 个独立元素，可按不同约定参数化<sup>2</sup>。若施加轴对称约束，独立元素降至 4 个。与其显式报告张量元素，不如使用更直观的参数：等向平均 _D_<sub>iso</sub>（衡量大小）、归一化各向异性 _D_<sub>Delta</sub>（衡量形状），以及极角与方位角（phi、theta），用于表征主对称轴在实验坐标中的取向<sup>7</sup>。在上图语境中，_D_<sub>iso</sub> 与 _D_<sub>Delta</sub>分别量化张量的大小与形状。_D_<sub>Delta</sub> 的取值范围从 −1/2（平面）到 0（球体）再到 +1（棒状）。

### DTD 的四维、二维与一维投影

一般六维 DTD _P_(**D**) 在轴对称情况下可写为四维分布 _P_(_D_<sub>iso</sub>, _D_<sub>Delta</sub>, theta, phi)，其大小、形状与取向在不同维度中清晰分离。对该分布在取向维度积分得到二维的大小-形状分布 _P_(_D_<sub>iso</sub>, _D_<sub>Delta</sub>)，进一步在形状维度积分可得到一维的大小分布 _P_(_D_<sub>iso</sub>)。

### 描述 DTD 的标量参数

我们定义了刻画 DTD 的大小、形状与取向三维度的均值与方差的标量度量。由于研究领域与读者对象不同，这些度量在原始论文中采用了不同的命名、符号与归一化方式，新入门者可能不易看出它们本质上表达的相同信息。各符号的汇编见此 [PDF](DTDmetrics.pdf)。

### DTD 方法

按对大小、形状、取向三个维度的刻画细粒度分类，当前仓库包含的 MD-dMRI 方法如下：

|           名称 |         参考文献          |    大小    |    形状    |   取向   | 算法 |
| -------------: | :-----------------------: | :--------: | :--------: | :------: | :--: |
|            dtd | Topgaard 2017<sup>1</sup> |    分布    |    分布    |   分布   | NNLS |
|      dtd_saupe | Topgaard 2016<sup>8</sup> |   单成分   |   单成分   | 有序张量 | NLSQ |
| dtd_covariance |  Westin 2016<sup>9</sup>  | 均值与方差 | 均值与方差 | 有序参数 | LLSQ |
|      dtd_gamma |  Lasič 2014<sup>10</sup>  | 均值与方差 |    均值    | 有序参数 | NLSQ |
|         dtd_pa | Martins 2016<sup>11</sup> |    分布    |    分布    |    -     | NNLS |
|   dtd_codivide |         Lampinen2         |   三成分   |   三成分   |    -     | NLSQ |
|        dtd_ndi |         Lampinen1         |   三成分   |   三成分   |    -     | NLSQ |
|       dtd_pake | Eriksson 2015<sup>7</sup> |   单成分   |   单成分   |    -     | NLSQ |

说明：NNLS = 非负最小二乘；NLSQ = 非线性最小二乘；LLSQ = 线性最小二乘。

## 扩散交换

细胞膜将细胞内与外部环境分隔开，是水分子交换的有效屏障。膜通透性受化学组成与通道蛋白（如水通道蛋白）的影响。我们提出了 MD-dMRI 方法量化具有不同局部扩散率的微观环境之间的分子交换速率<sup>12</sup>。在简单细胞系统中，交换速率可转换为膜通透性的定量指标<sup>13</sup>。

方法名：fexi11。参考：Lasič 2011<sup>12</sup>。

## 扩散与非相干流动

组织内的扩散与毛细血管网络中的流动有着截然不同的平移运动模式。我们的 MD-dMRI 方法依赖对流动与扩散的不同灵敏度的运动编码，以量化毛细血管密度<sup>14</sup>。

方法名：vasco16。参考：Ahlgren 2016<sup>14</sup>。

# 实现细节

与某一具体方法相关的所有函数位于 methods/name 目录中。该目录下需提供一组函数，遵循如下调用结构：

```matlab
m = name_1d_data2fit(signal, xps, opt, ind)
```

用途：对一条信号拟合模型。输入为一维信号向量（`signal`）、实验参数结构 `xps`（见下文）、由 `name_opt` 生成的选项结构 `opt`，以及可能用于子选择信号点的索引向量 `ind`。输出为一维模型参数向量 `m`，其中第一个参数通常反映整体信号强度。

```matlab
signal = name_1d_fit2data(m, xps)
```

用途：根据模型参数预测信号。输入为模型参数向量与实验参数结构 `xps`。输出为预测信号向量 `signal`。

```matlab
mfs_fn = name_4d_data2fit(s, mfs_fn, opt)
```

用途：对体数据中所有体素进行拟合。输入为输入结构 `s`（见下文）、模型拟合结构文件名 `mfs_fn` 与选项结构 `opt`。

```matlab
dps = name_4d_fit2datam(mfs_fn, dps_fn, opt)
```

用途：将拟合的模型参数转换为派生参数（例如由扩散张量元素计算 FA）。输入为模型拟合结构文件名 `mfs_fn`、派生参数文件名 `dps_fn` 与选项结构 `opt`。输出为派生参数结构。

```matlab
name_check_xps(xps)
```

用途：检查 `xps` 是否包含所需字段。

```matlab
name_opt(opt)
```

用途：向 `opt` 结构添加必要字段，但不覆盖已有字段。

```matlab
name_plot(signal, xps, h, h2)
```

用途：拟合信号并绘图。输入为信号向量 `signal`、实验参数结构 `xps` 以及两个图窗句柄 `h` 与 `h2`。

## 实验参数与输入结构

实验参数结构（`xps`）包含描述实验的信息，例如 b 值与 b-张量。输入结构（`s`）包含对 NIfTI 文件的引用、可选的掩模以及 xps。更多信息见：http://markus-nilsson.github.io/md-dmri/#p3

# 参考文献

1. D. Topgaard. Multidimensional diffusion MRI. J. Magn. Reson. 275, 98-113 (2017). [link](http://dx.doi.org/10.1016/j.jmr.2016.12.007)
2. D. Topgaard. NMR methods for studying microscopic diffusion anisotropy. In: R. Valiullin (Ed.) Diffusion NMR in confined systems: Fluid transport in porous solids and heterogeneous materials, New Developments in NMR 9, Royal Society of Chemistry, Cambridge, UK (2017). [link](http://dx.doi.org/10.1039/9781782623779-00226)
3. D. Le Bihan, E. Breton, D. Lallemand, P. Grenier, E. Cabanis, M. Laval-Jeantet. MR imaging of intravoxel incoherent motions - application to diffusion and perfusion in neurological disorders. Radiology 161, 401-407 (1986).
4. P.J. Basser, J. Mattiello, D. Le Bihan. Estimation of the effective self-diffusion tensor from the NMR spin echo. J. Magn. Reson. B 193, 247-254 (1994).
5. P.J. Basser, C. Pierpaoli. Microstructural and physiological features of tissues elucidated by quantitative-diffusion-tensor MRI. J. Magn. Reson. B 111, 209-219 (1996).
6. J.H. Jensen, J.A. Helpern, A. Ramani, H. Lu, K. Kaczynski. Diffusional kurtosis imaging: The quantification of non-Gaussian water diffusion by means of magnetic resonance imaging. Magn. Reson. Med. 53, 1432-1440 (2005).
7. S. Eriksson, S. Lasič, M. Nilsson, C.-F. Westin, D. Topgaard. NMR diffusion encoding with axial symmetry and variable anisotropy: Distinguishing between prolate and oblate microscopic diffusion tensors with unknown orientation distribution. J. Chem. Phys. 142, 104201 (2015). [link](http://dx.doi.org/10.1063/1.4913502)
8. D. Topgaard. Director orientations in lyotropic liquid crystals: Diffusion MRI mapping of the Saupe order tensor. Phys. Chem. Chem. Phys. 18, 8545-8553 (2016). [link](http://dx.doi.org/10.1039/c5cp07251d)
9. C.-F. Westin, H. Knutsson, O. Pasternak, F. Szczepankiewicz, E. Özarslan, D. van Westen, C. Mattisson, M. Bogren, L. O'Donnell, M. Kubicki, D. Topgaard, M. Nilsson. Q-space trajectory imaging for multidimensional diffusion MRI of the human brain. Neuroimage 135, 345-362 (2016). [link](http://dx.doi.org/10.1016/j.neuroimage.2016.02.039)
10. S. Lasič, F. Szczepankiewicz, S. Eriksson, M. Nilsson, D. Topgaard. Microanisotropy imaging: quantification of microscopic diffusion anisotropy and orientational order parameter by diffusion MRI with magic-angle spinning of the q-vector. Front. Physics 2, 11 (2014). [link](http://dx.doi.org/10.3389/fphy.2014.00011)
11. J.P. de Almeida Martins, D. Topgaard. Two-dimensional correlation of isotropic and directional diffusion using NMR. Phys. Rev. Lett. 116, 087601 (2016). [link](http://dx.doi.org/10.1103/PhysRevLett.116.087601)
12. S. Lasič, M. Nilsson, J. Lätt, F. Ståhlberg, D. Topgaard. Apparent exchange rate (AXR) mapping with diffusion MRI. Magn. Reson. Med. 66, 356-365 (2011). [link](http://dx.doi.org/10.1002/mrm.22782)
13. I. Åslund, A. Nowacka, M. Nilsson, D. Topgaard. Filter-exchange PGSE NMR determination of cell membrane permeability. J. Magn. Reson. 200, 291-295 (2009). [link](http://dx.doi.org/10.1016/j.jmr.2009.07.015)
14. A. Ahlgren, L. Knutsson, R. Wirestam, M. Nilsson, F. Ståhlberg, D. Topgaard, S. Lasič. Quantification of microcirculatory parameters by joint analysis of flow-compensated and non-flow-compensated intravoxel incoherent motion (IVIM) data. NMR Biomed. 29, 640-649 (2016). [link](http://dx.doi.org/10.1002/nbm.3505)
