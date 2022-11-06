*这篇文章基本是 `rpm-list-builder` 官方[用户指南](https://github.com/hroncok/rpm-list-builder/blob/python310/docs/users_guide.md)的翻译*

本文档是用实际命令行解释用例。如果您想要参阅示例，您也可以参考集成测试脚本 [tests/integration/run.sh](/app/joplin-desktop/resources/tests/integration/run.sh "../tests/integration/run.sh") 内部的 test_foo 方法。

有关配方文件格式的文档，请参阅 [RHSCL Rebuild Recipes](https://github.com/sclorg/rhscl-rebuild-recipes) 。

## 架构

该应用程序用于帮助构建一系列的 RPM 包。

它的工作流程由“主应用程序/Main application”、“配方/Recipe”、“下载/Download”、“构建/Build”、“工作目录/Work directory”几个部分组成。

“Main application”是一个主应用程序，它将从配方文件中获取已定义的 RPM 包列表的 “Recipe” 数据，并下载并构建它们。

“Download”是获取这一系列 RPM 包的源代码的过程。

“Build”是构建一系列的 RPM 包的过程。

“Main”将调用“Download”和“Build”过程。

“Work directory”将管理工作目录结构。 有关详细信息，请参阅下面的部分。

### 架构要素

```
Main --> Recipe (recipe file)
 |
 +-----> Download +-----> 从本地获取包
 |                |
 |                +-----> 使用 fedpkg (或者 rhpkg) cone 从软件源获取包
 |                |
 |                +-----> 自定义下载 -> 在配置文件中定义行为
 |
 +-----> Build ---+-----> Mock Build
                  |
                  +-----> Copr Build
                  |
                  +-----> Koji Build
                  |
                  +-----> Custom Build -> 在配置文件中定义行为
```

### 配方文件、源目录和工作目录的关系

#### 配方文件（`ror50.yml`)

```
rh-ror50:
  packages:
    - rh-ror50:
        macros:
          install_scl: 0
    # Packages required by RSpec, Cucumber
    - rubygem-rspec
    - rubygem-rspec-core:
        replaced_macros:
          need_bootstrap_set: 1
    - rubygem-rspec-support:
        replaced_macros:
          need_bootstrap_set: 1
    - rubygem-diff-lcs:
        macros:
          _with_bootstrap: 1
```

#### 源目录

如果您想在本地环境中从 `SOURCE_DIRECTORY` 上的包构建软件包， `SOURCE_DIRECTORY` 的结构如下所示——只需将软件包放在同一目录中即可。

```
source_directory/
├── rh-ror50
│   ├── LICENSE
│   ├── README
│   ├── rh-ror50.spec
│   └── sources
├── rubygem-diff-lcs
│   ├── rubygem-diff-lcs.spec
│   └── sources
├── rubygem-rspec
│   ├── rubygem-rspec.spec
│   └── sources
├── rubygem-rspec-core
│   ├── rspec-core-3.5.4-Fixes-for-Ruby-2.4.patch
│   ├── rspec-related-create-full-tarball.sh
│   ├── rubygem-rspec-core.spec
│   └── sources
└── rubygem-rspec-support
    ├── rspec-related-create-full-tarball.sh
    ├── rubygem-rspec-support-3.2.1-callerfilter-searchpath-regex.patch
    ├── rubygem-rspec-support-3.6.0.beta2-fix-for-ruby-2.4.0.patch
    ├── rubygem-rspec-support-3.6.0.beta2-fix-for-ruby-2.4.0-tests.patch
    ├── rubygem-rspec-support.spec
    └── sources
```

#### 工作目录

1.  应用程序会创建用以构建的目录。其中每个子目录的名称都是数字，用以表明构建的顺序。目录名称开头可以用零填充 ( `0..00N`) 。
    
2.  应用程序将原始 spec 文件重命名为 `foo.spec.orig`, 并创建编辑过的新文件 `foo.spec`以在配方文件中注入宏定义。
    

```
work_directory/
├── 1
│   └── rh-ror50
│       ├── LICENSE
│       ├── README
│       ├── rh-ror50.spec
│       ├── rh-ror50.spec.orig
│       └── sources
├── 2
│   └── rubygem-rspec
│       ├── rubygem-rspec.spec
│       ├── rubygem-rspec.spec.orig
│       └── sources
├── 3
│   └── rubygem-rspec-core
│       ├── rspec-core-3.5.4-Fixes-for-Ruby-2.4.patch
│       ├── rspec-related-create-full-tarball.sh
│       ├── rubygem-rspec-core.spec
│       ├── rubygem-rspec-core.spec.orig
│       └── sources
├── 4
│   └── rubygem-rspec-support
│       ├── rspec-related-create-full-tarball.sh
│       ├── rubygem-rspec-support-3.2.1-callerfilter-searchpath-regex.patch
│       ├── rubygem-rspec-support-3.6.0.beta2-fix-for-ruby-2.4.0.patch
│       ├── rubygem-rspec-support-3.6.0.beta2-fix-for-ruby-2.4.0-tests.patch
│       ├── rubygem-rspec-support.spec
│       ├── rubygem-rspec-support.spec.orig
│       └── sources
└── 5
    └── rubygem-diff-lcs
        ├── rubygem-diff-lcs.spec
        ├── rubygem-diff-lcs.spec.orig
        └── sources
```

## 教程

1.  首先，运行以下命令以查看命令帮助。
    
    ```
     $ rpmlb -h 
    ```
    
2.  下边是 `rpmlb`的基本形式。 您必须设置正确的下载类型、构建类型、配方文件、reicpe ID。 如果你省略 `--download`, `--build`, 那就会使用默认值。 您也可以使用短选项名称。 有关更多详细信息，请参阅命令帮助。
    
    ```
     $ rpmlb \
       --download DOWNLOAD_TYPE \
       --build BUILD_TYPE \
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

### 选择 Download 类型

#### 本地

1.  如果您尚未将您的软件包提交到软件源，您可能希望在本地环境中从 `SOURCE_DIRECTORY` 上构建您的软件包。 在这种情况下，运行
    
    ```
     $ rpmlb \
       --download local \
       --source-directory SOURCE_DIRECTORY \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

#### Fedpkg

1.  如果您尚未将您的软件包提交到软件源，您可能想要从软件源中的包进行构建。在这种情况下，运行 `--branch`.
    
    ```
     $ rpmlb \
       --download fedpkg \
       --branch BRANCH \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

#### Rhpkg

1.  如果你想使用 `rhpkg`代替 `fedpkg`, 运行 `--download rhpkg`。其他选项同上。
    
    ```
     $ rpmlb \
       --download rhpkg \
       --branch BRANCH \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

#### 自定义

1.  如果你想自定义下载方式，使用 `--custom-file`.
    
    ```
     $ rpmlb \
       ...
       --download custom \
       --custom-file CUSTOM_FILE \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    
2.  什么是自定义文件？ 请参阅 示例自定义文件 。 它是 YAML 文件，如 .travis.yml. 您可以在文件中编写 shell 脚本。
    
    - `before_download`：在构建之前编写要运行的命令。
    - `download`：为 pacakges 目录中的每个包编写要运行的命令。 您可以使用环境变量 PKG来描述包名。

对于这两个钩子，环境变量 CUSTOM_DIR指包含自定义文件的目录 （允许配置文件和帮助脚本相对于它定位）。

### 指定工作目录

1.  默认的工作目录是 `/tmp/rpmlb-XXXXXXXX`。不过你可以指定 `--work-directory` 以改变运行目录。
    
    ```
     $ rpmlb \
       ...
       --work-directory WORK_DIRECTORY \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

### 选择构建类型

#### Mock 构建

1.  如果你想用模拟构建，运行 `--mock-config`（与 `mock -r` 相同）。
    
    ```
     $ rpmlb \
       ...
       --build mock \
       --mock-config MOCK_CONFIG \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

#### Copr 构建

1.  您应当自行准备 copr repo 以便构建。不支持通过脚本创建 copr repo 的功能。
    
2.  如果要删除 copr 中的软件包，请运行
    
    ```
     $ scripts/delete_copr_pkgs.sh COPR_REPO 
    ```
    
3.  要为 Copr 构建，请运行
    
    ```
     $ rpmlb \
       ...
       --build copr \
       --copr-repo COPR_REPO \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

#### Koji 构建

1.  确保您有所需的 koji 实例的配置
    (i.e. [Fedora Koji](https://koji.fedoraproject.org/koji/), [CentOS CBS](https://cbs.centos.org/koji/), …) 安装在您的系统上。
    
    - 如果不确定，那么检查
        `/etc/koji.conf.d/<profile>.conf` 是否存在.
2.  要为任何 Koji 实例构建，请输入
    
    ```
    $ rpmlb
      ...
      --build koji \
      --koji-epel EPEL_VERSION \
      --koji-profile PROFILE \
      --koji-owner OWNER \
      ...
      RECIPE_FILE \
      COLLECTION_ID 
    ```
    

这里， `EPEL_VERSION` 是您希望构建的主要 EL 版本 （例如 CentOS 7 那就是 `7` )， `PROFILE` 命名配置文件 使用（它的作用与 `koji --profile` 选项相同）， `OWNER` 是应该拥有构建目标中的任何新包的用户的名称。

您还可以指定 `--koji-scratch` 以测试您的构建。

如果构建目标名称不遵循 [CBS](https://cbs.centos.org/koji/) ， 其中每个目标被命名为 `sclo{el}-{collection}-rh-el{el}` , 您可以使用 `--koji-target-format` 选项覆盖此模板。在选择要构建的目标时，任何 `{el}`, `{collection}` 占位符将替换为 EL 版本和 SCL 名称。

#### 自定义构建

1.  如果需要自定义构建方式，运行 `--custom-file`.
    
    ```
     $ rpmlb \
       ...
       --build custom \
       --custom-file CUSTOM_FILE \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    
2.  什么是自定义文件？ 请参阅 [示例自定义文件](https://github.com/hroncok/rpm-list-builder/blob/python310/tests/fixtures/custom) 。 它是 YAML 文件，如 `.travis.yml` ，您可以此文件中编写 shell 脚本。
    

- `before_build`: 在构建之前编写要运行的命令。
- `build`: 为 pacakges 目录中的每个包编写要运行的命令。 您可以使用环境变量 `PKG` 来描述包名。

对于这两个钩子，环境变量 `CUSTOM_DIR` 指包含自定义文件的目录 （允许配置文件和帮助脚本相对于它定位）。

#### 不做构建

1.如果您不想构建，只想下载 pacakges 创建工作目录或者检查 spec 以便后来使用。这种情况下，运行时 **不要** `--build` 选项或者使用 `--build dummy`.

```
 $ rpmlb \
      ...
      --build dummy \
      ...
      RECIPE_FILE \
      COLLECTION_ID 
```

### 从任何位置恢复

1.  如果由于某些原因您的构建在此过程中失败，您希望恢复构建过程，继续构建。这种情况下，请使用 `--work-directory` 和 `--resume`。`--resume` 的参数是包的编号，首部可以用 0 填充，例如 01 => 1, 012 => 12.
    
    ```
     $ rpmlb \
       ...
       --build BUILD_TYPE \
       --work-directory WORK_DIRECTORY \
       --resume 35 \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

### 指定构建的重试次数

1.  您可以为构建设置重试次数。 例如，下面的示例显示在第一次构建失败后构建运行了 3 次，也就是总计尝试构建 4 次。 如果未指定此重试选项，则重试计数为零。（重试功能被禁用）
    
    ```
     $ rpmlb \
       ...
       --retry 3 \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

### 明确指定一个打包包命令

1.  打包命令 `fedpkg` 或 `rhpkg` 在以下几个构建类型中都有使用： Mock, Copr。 如果要从命令选项指定命令，使用 `--cmd-pkg` 选项.
    
2.  如果 `--download fedpkg or rhpkg` 被指定，在构建中也会使用打包命令。
    
3.  如果下载类型不是 `fedpkg` 也不是 `rhpkg`， 那 `fedpkg` 用作默认的打包命令。
    
    ```
     $ rpmlb \
       ...
       --download fedpkg \
       --build copr \
       --copr-repo COPR_REPO \
       --pkg-cmd rhpkg \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    

### 指定发行版模式

1.  您也许想要构建特定的软件包，编辑 PRM Spec 文件或者为特定发行版运行 `path` 命令。这种情况下，可以使用 `--dist` 选项或者在配方文件中指定 `DIST` 环境变量。
    
    ```
     $ rpmlb \
       ...
       --dist centos \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    
2.  我们目前支持 `fc`, `fc26`, `centos`, `centos7`, `el`, `el7` 作为 `--dist` 的参数。
    

### 配方文件、自定义文件和环境变量

1.  您可以在配方文件或自定义文件中使用环境变量（ `cmd`元素）。
    
    ```
     $ FOO=foo BAR=bar rpmlb \
       ...
       RECIPE_FILE \
       COLLECTION_ID 
    ```
    
2.  配方文件
    
    ```
     joke:
       name: Joke
       packages:
         - sl:
             cmd: echo "${FOO}" 
    ```
    
3.  自定义文件
    
    ```
     build:
       - echo "${BAR}" 
    ```
