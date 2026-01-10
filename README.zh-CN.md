# 多维扩散磁共振成像（MD‑dMRI）

多维扩散磁共振成像（MD‑dMRI）是一类在概念上相关的方法家族，它依赖先进的梯度调制方案和数据处理方法，通过将这些因素对检测到的MRI信号的影响分解到多个采集与分析维度，从而同时定量组织的多种微结构与动力学特性。

本GitHub仓库主要包含用于MD‑dMRI数据分析的MATLAB软件，也包含一些用于采集协议设置、运动校正与图像可视化的辅助例程。

目前在MD‑dMRI框架内实现的三大方法族：
- 扩散张量分布（Diffusion tensor distributions）
- 扩散交换（Diffusional exchange）
- 扩散与非相干流动（Diffusion and incoherent flow）

这些方法在[这里](methods/README.md)有简要说明，在两篇综述文章中有更多细节说明（见上标参考1、2），并在各自的原始论文中有更为详尽的阐述。

## 快速开始

在根目录运行 `setup_paths` 将文件加入Matlab路径。

要分析数据，可以使用 `method_name_4d_data2fit` 与 `method_name_4d_fit2param` 函数，其中 `method_name` 对应[这里](methods)实现的某个方法。或者，也可以使用 `mdm_fit` 命令。可通过 `mdm_fit --help` 查看用法概览。示例如下：

```matlab
mdm_fit --data input/data.nii.gz ...
    --mask tmp/mask.nii.gz ...
    --method dtd_codivide ...
    --out tmp/ ...
    --xps input/data_xps.mat;
```

`--data` 参数应指向一个NIfTI文件。`--mask` 参数为可选项，但提供例如脑掩模可避免对背景体素进行分析，从而加速处理。关于可用的 `--method` 参数，请参见 methods 文件夹。`--out` 参数接收一个文件夹/前缀作为输入。最后，需要提供实验执行方式的信息：要么使用 `--xps` 标志，其参数指向包含“实验参数结构”（xps）的 .mat 文件；要么（仅对扩散张量分布 dtd 方法）向 `--btens` 标志提供b‑tensor文件。

我们假定在调用该函数之前数据已完成预处理。预处理应包括运动与涡流校正以及必要的平滑处理。本框架也支持这些步骤（见[下文](#motion-and-eddy-current-correction)）。

xps或b‑tensor输入的构建可能具有一定难度，下文提供了部分帮助（见[下文](#construction-of-the-xps)）。

## 图形界面（GUI）

函数 `mgui` 可启动一个用于数据质量检查的图形界面。左侧面板显示文件夹结构。当打开如 data.nii.gz 这类数据文件且GUI能找到同名的 data_xps.mat 时，会自动加载它。随后可绘制ROI，并在右侧“analysis”面板的下拉菜单中选择不同方法对信号数据进行拟合。

![Image](http://markus-nilsson.github.io/md-dmri/mgui.png)

<a id="motion-and-eddy-current-correction"></a>

## 运动与涡流校正

传统的运动校正（将所有数据配准到 b = 0 s/mm<sup>2</sup> 的体积）由 `mdm_mec_b0` 实现。该方法并不适合高b值数据，高b值下应采用如基于外推的配准方法（参见[本文](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0141825)）。`mdm_mec_eb` 提供了此类支持。示例如下：

```matlab
% 选项
opt = mdm_opt();
 
% 连接到数据
s.nii_fn = fullfile(pwd, 'data.nii');
s.xps = mdm_xps_from_bval_bvec('data.bval', 'data.bvec');

% 确定输出路径
o_path = pwd;
 
% 写出 elastix 参数文件
p = elastix_p_affine(200);
p_fn = elastix_p_write(p, 'p.txt');
  
% 运行基于外推的配准
s_registered = mdm_s_mec(s, p_fn, o_path, opt);
```

现在 `s_registered` 可用于后续分析。

<a id="construction-of-the-xps"></a>

## 构建 xps

xps 保存所有相关实验信息，即实验是如何执行的。所有变量均使用SI单位，并按照[此规范](mdm/readme.txt)预定义命名。请参见 `mdm_xps_*` 函数以获取构建xps的帮助。下面给出两个示例：首先是分析单个nii文件的情况；其次是如何合并多个nii文件并进行联合分析。

**基于单个nii文件创建xps**

如果分析基于单个nii文件，则使用一个路径定义其位置 `s.nii_fn = 'nii_filename.nii';`。每个nii文件通常伴随包含扩散编码方向与b值信息的文件。这些文件可用于自动生成xps结构。可调用：

```matlab 
s.xps = mdm_xps_from_gdir('gdir_filename.txt', b_delta);
```
或

```matlab
s.xps = mdm_xps_from_bval_bvec('bval_filename.bval', 'bvec_filename.bvec', b_delta);
```

具体使用哪一种取决于可用的文件格式。注意，这些文件目前不包含b‑tensor形状信息，因此需要用户指定 `b_delta`。此外，可以通过 `mdm_fn_nii2gdir` 或 `mdm_fn_nii2bvalbvec` 根据 `nii_fn` 自动生成 gdir.txt 与 .bval/.bvec 的路径。生成的xps可使用 `mdm_xps_save` 保存。如果保存xps的 .mat 文件名与nii文件名之间的关系符合 `mdm_xps_fn_from_nii_fn` 的约定，框架会自动找到该xps。

**示例：基于单个nii文件生成xps**

此示例仅需用户定义用来创建并保存对应xps的nii文件名。注意，这里假设 gdir.txt 或 .bval/.bvec 文件与nii位于同一文件夹且采用标准化命名。

```matlab
% 定义nii文件路径 
s.nii_fn = 'path_to_nii.nii';

% 假设编码为线性
b_delta   = 1;

% 获取对应gdir路径并生成xps
gdir_fn   = mdm_fn_nii2gdir(s.nii_fn, b_delta);
s.xps     = mdm_xps_from_gdir(gdir_fn, b_delta);

% 或获取对应bval/bvec路径并生成xps
[bval_fn, bvec_fn] = mdm_fn_nii2bvalbvec(s.nii_fn);
s.xps     = mdm_xps_from_bval_bvec(bval_fn, bvec_fn, b_delta);

% 最后，保存xps。
xps_fn    = mdm_xps_fn_from_nii_fn(s.nii_fn);
mdm_xps_save(s.xps, xps_fn)
```

**基于多个nii文件创建xps**

在某些情况下，无法在单个序列中采集所有必要数据，因而需要在分析中合并多个nii文件。例如，线性与球形b‑tensor编码通常在两个独立序列中完成，但我们希望联合分析它们。当分析依赖多个nii文件时，首先创建一个由若干部分 `s` 结构组成的单元格数组，然后调用 `mdm_s_merge` 将它们合并为一个。也可以分别使用 `mdm_nii_merge` 与 `mdm_xps_merge` 合并nii文件与xps结构。

**示例：基于多个nii文件生成xps**

此示例复用前述示例中的工具。假设所有必要的nii文件都给出了完整路径，且同一文件夹内存在采用标准命名的对应 gdir.txt 或 .bval/.bvec 文件（参见 `mdm_fn_nii2gdir` 与 `mdm_fn_nii2bvalbvec` 的标准命名约定）。所有必要的nii文件与对应xps结构首先存入一个由结构体组成的单元格数组，然后将该部分 `s` 结构的单元格数组进行合并。注意，该示例仅展示使用 gdir.txt 创建xps 的情形；如需使用 .bval/.bvec，可按前述示例修改。

```matlab
% 创建 s 结构的单元格数组
s{1}.nii_fn = 'nii_filename_1.nii';
s{2}.nii_fn = 'nii_filename_2.nii';
s{3}.nii_fn = 'nii_filename_3.nii';

% 对应的b‑tensor形状：此处依次为球形、线性与平面
b_deltas  = [0 1 -.5];

% 为合并后的nii（输出）定义名称
merged_nii_path = '.../output_directory/';
merged_nii_name = 'merged_nii_name.nii';

% 遍历nii文件生成部分xps结构，并存入单元格数组
for i = 1:numel(file_list)
    gdir_fn  = mdm_fn_nii2gdir(s{i}.nii_fn);
    s{i}.xps = mdm_xps_from_gdir(gdir_fn, [], b_deltas(i));
end

% 合并 s 结构，并将合并后的nii与对应的 xps.mat 文件写出
s_merged = mdm_s_merge(s, merged_nii_path, merged_nii_name);
```

可通过阅读 mdm/readme.txt 熟悉 xps 结构。关于代码结构的详细说明请见：http://markus-nilsson.github.io/md-dmri/。

## 参考文献

Markus Nilsson, Filip Szczepankiewicz, Björn Lampinen, André Ahlgren, 
João P. de Almeida Martins, Samo Lasic, Carl-Fredrik Westin, and Daniel Topgaard.
An open-source framework for analysis of multidimensional diffusion MRI data implemented in MATLAB.
Proc. Intl. Soc. Mag. Reson. Med. (26), Paris, France, 2018. http://archive.ismrm.org/2018/5355.html

## 方法特定参考（持续更新）

1) `methods/dtd_smr`
用于拟合论文《Towards unconstrained compartment modeling in white matter using diffusion-relaxation MRI with tensor-valued diffusion encoding》中模型的代码，发表于2020年3月6日，期刊：MRM。另见 https://github.com/belampinen/lampinen_mrm_2019。

2) `methods/ning18`
用于拟合论文《Time dependence in diffusion MRI predicts tissue outcome in ischemic stroke patients》的代码，投稿期刊：MRM（2020年）。
