---
tags:
  - Gentoo
  - Linux
---

# emerge 装包 ninja 报错“manifest 'build.ninja' still dirty after 100 tries”解决方法

在新系统修改编译 flag 后，重新编译系统里所有包时，运行了如下命令：

```
emerge -Deuav world
```

报错如下：

```
* Messages for package net-libs/nghttp2-1.61.0:

 * ERROR: net-libs/nghttp2-1.61.0::gentoo failed (compile phase):
 *   ninja -v -j16 -l16 failed
 *
 * Call stack:
 *     ebuild.sh, line  136:  Called src_compile
 *   environment, line 2565:  Called cmake-multilib_src_compile
 *   environment, line  776:  Called multilib-minimal_src_compile
 *   environment, line 1904:  Called multilib_foreach_abi 'multilib-minimal_abi_src_compile'
 *   environment, line 2171:  Called multibuild_foreach_variant '_multilib_multibuild_wrapper' 'multilib-minimal_abi_src_compile'
 *   environment, line 1864:  Called _multibuild_run '_multilib_multibuild_wrapper' 'multilib-minimal_abi_src_compile'
 *   environment, line 1862:  Called _multilib_multibuild_wrapper 'multilib-minimal_abi_src_compile'
 *   environment, line  531:  Called multilib-minimal_abi_src_compile
 *   environment, line 1898:  Called multilib_src_compile
 *   environment, line 2391:  Called cmake_src_compile
 *   environment, line  894:  Called cmake_build
 *   environment, line  861:  Called eninja
 *   environment, line 1332:  Called die
 * The specific snippet of code:
 *       "$@" || die -n "${*} failed"
 *
 * If you need support, post the output of `emerge --info '=net-libs/nghttp2-1.61.0::gentoo'`,
 * the complete build log and the output of `emerge -pqv '=net-libs/nghttp2-1.61.0::gentoo'`.
 * The complete build log is located at '/var/tmp/portage/net-libs/nghttp2-1.61.0/temp/build.log'.
 * The ebuild environment file is located at '/var/tmp/portage/net-libs/nghttp2-1.61.0/temp/environment'.
 * Working directory: '/var/tmp/portage/net-libs/nghttp2-1.61.0/work/nghttp2-1.61.0_build-abi_x86_64.amd64'
 * S: '/var/tmp/portage/net-libs/nghttp2-1.61.0/work/nghttp2-1.61.0'
```

其中日志文件 `/var/tmp/portage/net-libs/nghttp2-1.61.0/temp/build.log` 报错如下：

```
ninja: error: manifest 'build.ninja' still dirty after 100 tries, perhaps system time is not set
 * ERROR: net-libs/nghttp2-1.61.0::gentoo failed (compile phase):
 *   ninja -v -j16 -l16 failed
 *
 * Call stack:
 *     ebuild.sh, line  136:  Called src_compile
 *   environment, line 2565:  Called cmake-multilib_src_compile
 *   environment, line  776:  Called multilib-minimal_src_compile
 *   environment, line 1904:  Called multilib_foreach_abi 'multilib-minimal_abi_src_compile'
 *   environment, line 2171:  Called multibuild_foreach_variant '_multilib_multibuild_wrapper' 'multilib-minimal_abi_src_compile'
 *   environment, line 1864:  Called _multibuild_run '_multilib_multibuild_wrapper' 'multilib-minimal_abi_src_compile'
 *   environment, line 1862:  Called _multilib_multibuild_wrapper 'multilib-minimal_abi_src_compile'
 *   environment, line  531:  Called multilib-minimal_abi_src_compile
 *   environment, line 1898:  Called multilib_src_compile
 *   environment, line 2391:  Called cmake_src_compile
 *   environment, line  894:  Called cmake_build
 *   environment, line  861:  Called eninja
 *   environment, line 1332:  Called die
 * The specific snippet of code:
 *       "$@" || die -n "${*} failed"
 *
 * If you need support, post the output of `emerge --info '=net-libs/nghttp2-1.61.0::gentoo'`,
 * the complete build log and the output of `emerge -pqv '=net-libs/nghttp2-1.61.0::gentoo'`.
 * The complete build log is located at '/var/tmp/portage/net-libs/nghttp2-1.61.0/temp/build.log'.
 * The ebuild environment file is located at '/var/tmp/portage/net-libs/nghttp2-1.61.0/temp/environment'.
 * Working directory: '/var/tmp/portage/net-libs/nghttp2-1.61.0/work/nghttp2-1.61.0_build-abi_x86_64.amd64'
 * S: '/var/tmp/portage/net-libs/nghttp2-1.61.0/work/nghttp2-1.61.0'
```

报错的原因是系统刚装好进行了时间同步， ninja 编译发现有一些文件是在未来创建的。解决方法为找到所有在未来创建的文件，并将其时间戳修改为现在：

```
touch currtime
find / -cnewer currtime -exec touch {} \;
rm currtime
```

最后单独重新编译这一个包：

```
emerge -av =net-libs/nghttp2-1.61.0
```

## 参考资料

https://forums.gentoo.org/viewtopic-p-8768044.html?sid=ed3fa313c3404a3db1ef5260515270ef
