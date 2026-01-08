# DTD 及相关方法参数汇总表

## 张量分布方法 (Diffusion Tensor Distribution)

| 方法名 | 文献 | 输出维度 | 参数定义 | 区间说明 |
|------|------|--------|--------|--------|
| **dtd_cumulant** | Nilsson (author comment) | 84 | S0、二阶张量(6)、四阶累积量(21)、六阶累积量(56) | m(1): S0; m(2:7): 均值张量 6 分量 (SI单位: µm²/ms); m(8:28): 四阶累积量 21 分量 (SI单位: µm⁴/ms²); m(29:84): 六阶累积量 56 分量 (SI单位: µm⁶/ms³) |
| **dtd_covariance** | Westin et al. (2016) NeuroImage 135:345-362 | 28 | S0、均值张量(6)、四阶协方差(21) | m(1): S0; m(2:7): 均值扩散张量 6 分量 (SI单位: µm²/ms); m(8:28): 协方差张量 21 分量 (SI单位: µm⁴/ms²) |
| **dtd_gamma** | Lasič et al. (2014) Front. Phys. 2:11 | 4+ns* | S0、平均扩散率(MD)、各向同性方差(Vi)、各向异性方差(Va)、多个S0 | m(1): S0; m(2): MD (µm²/ms); m(3): Vi (µm⁴/ms²); m(4): Va (µm⁴/ms²); m(5:4+ns): 多个信号系列的相对 S0 |
| **dtd_pake** | Eriksson et al. (2015) J. Chem. Phys. 142:104201 | 3 | S0、等向扩散系数(D_iso)、归一化各向异性(D_delta) | m(1): S0; m(2): D_iso (µm²/ms); m(3): D_delta (-0.5~1, 其中 -0.5=平面, 0=球体, 1=棒状) |
| **dtd_pa** | Topgaard (2017) J. Magn. Reson. 275:98 | 可变 | 分布式参数 (NNLS 反演) | 输出为大量节点上的分布值，代表 D_iso 和 D_delta 联合分布 P(D_iso, D_delta) |
| **dtd_codivide** | Lampinen et al. (2016) NeuroImage (minor revision) | 5+ns | S0、自由水体积分数(v_at)、各向异性体积分数(v_fw)、组织MD、自由水MD | m(1): S0; m(2): v_at (各向异性组织体积分数); m(3): v_fw (自由水体积分数); m(4): MD (组织, µm²/ms); m(5): MD_fw (自由水, 固定3.0 µm²/ms); m(6:5+ns): 多个信号系列参数 |

*注: ns 为多信号系列数 (由 xps.s_ind 决定)

## DTI 及相关方法

| 方法名 | 文献 | 输出维度 | 参数定义 | 区间说明 |
|------|------|--------|--------|--------|
| **dti_lls** | - | 7 | S0、张量 6 分量 | m(1): S0; m(2:7): 扩散张量 6 独立分量 (µm²/ms) |
| **dti_nls** | - | 7 | S0、张量 6 分量 (非线性最小二乘) | m(1): S0; m(2:7): 扩散张量 6 独立分量 (µm²/ms) |
| **dki_lls** | - | 22 | S0、张量 6 分量、峰度 15 分量 | m(1): S0; m(2:7): 扩散张量; m(8:22): 峰度张量 15 分量 |

## 其他扩散模型

| 方法名 | 文献 | 输出维度 | 参数定义 | 区间说明 |
|------|------|--------|--------|--------|
| **ivim** | - | 4 | S0、灌注分数(f)、快速扩散系数、慢速扩散系数 | m(1): S0; m(2): f (灌注信号分数); m(3): D_fast (快速扩散, µm²/ms); m(4): D_slow (慢速扩散, µm²/ms) |
| **ning18** | - | 5 | S0、MD、扩散方差(V)、峰度项(V*k)、拟合剩余方差 | m(1): S0; m(2): MD (µm²/ms); m(3): V (µm⁴/ms²); m(4): V*k; m(5): 残差方差 |

## 通用单位转换说明

- **SI 单位**: m²/s (标准国际单位)
- **代码内部计量**: SI 单位 × 1e-9 = µm²/ms (更常用于 dMRI)
- **二阶张量系数**: × 1e-9 转换为 SI，× 1e-9 逆转换为 µm²/ms
- **四阶张量系数**: × 1e-18 转换为 SI，× 1e-18 逆转换为 µm⁴/ms²
- **六阶张量系数**: × 1e-27 转换为 SI，× 1e-27 逆转换为 µm⁶/ms³

## 关键参数说明

| 缩写 | 全称 | 物理含义 |
|-----|------|--------|
| S0 | Signal at zero diffusion | 无扩散加权信号强度 |
| MD | Mean Diffusivity | 平均扩散系数 (各向同性部分) |
| FA | Fractional Anisotropy | 部分各向异性 |
| MK_I / MKi | Mean Kurtosis Isotropic | 各向同性峰度 |
| MK_A / MKa | Mean Kurtosis Anisotropic | 各向异性峰度 |
| Vi | Isotropic Variance | 各向同性方差 (分布宽度) |
| Va | Anisotropic Variance | 各向异性方差 (形状分布宽度) |
| AD | Axial Diffusivity | 轴向扩散系数 |
| RD | Radial Diffusivity | 径向扩散系数 |
| D_iso | Isotropic Diffusivity | 等向扩散系数 |
| D_delta | Normalized Anisotropy | 归一化各向异性 (-0.5~1) |

## 算法分类

| 算法类型 | 说明 | 包含方法 |
|--------|------|--------|
| LLSQ | Linear Least Squares | dtd_covariance, dti_lls, dki_lls |
| NLSQ | Nonlinear Least Squares | dtd_gamma, dtd_pake, dtd_codivide, dti_nls, ivim |
| NNLS | Non-negative Least Squares | dtd_pa, dtd (未在代码中) |
