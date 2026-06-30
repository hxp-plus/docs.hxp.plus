---
tags:
  - python
---

# Arch Linux 手动修复 pip 依赖错误

Today I tired to install cpupower-gui on my BlackArch Linux. I installed it via yay.

```shell
yay -S cpupower-gui
```

And pip said:

```shell
Traceback (most recent call last):
  File "/usr/bin/meson", line 6, in <module>
    from pkg_resources import load_entry_point
  File "/usr/lib/python3.8/site-packages/pkg_resources/__init__.py", line 80, in <module>
    import appdirs
ModuleNotFoundError: No module named 'appdirs'
==> ERROR: A failure occurred in build().
    Aborting...
Error making: cpupower-gui
```

After upgrading to BlackArch Linux, pip keeps failing.

I tried to install appdirs by invoking pip in this way:

```shell
python -m pip install appdirs
```

But it told me that `pyparsing` is needed.

```shell
Traceback (most recent call last):
  File "/usr/lib/python3.8/runpy.py", line 193, in _run_module_as_main
    return _run_code(code, main_globals, None,
  File "/usr/lib/python3.8/runpy.py", line 86, in _run_code
    exec(code, run_globals)
  File "/usr/lib/python3.8/site-packages/pip/__main__.py", line 16, in <module>
    from pip._internal.main import main as _main  # isort:skip # noqa
  File "/usr/lib/python3.8/site-packages/pip/_internal/main.py", line 13, in <module>
    from pip._internal.cli.autocompletion import autocomplete
  File "/usr/lib/python3.8/site-packages/pip/_internal/cli/autocompletion.py", line 11, in <module>
    from pip._internal.cli.main_parser import create_main_parser
  File "/usr/lib/python3.8/site-packages/pip/_internal/cli/main_parser.py", line 7, in <module>
    from pip._internal.cli import cmdoptions
  File "/usr/lib/python3.8/site-packages/pip/_internal/cli/cmdoptions.py", line 28, in <module>
    from pip._internal.models.target_python import TargetPython
  File "/usr/lib/python3.8/site-packages/pip/_internal/models/target_python.py", line 4, in <module>
    from pip._internal.utils.misc import normalize_version_info
  File "/usr/lib/python3.8/site-packages/pip/_internal/utils/misc.py", line 19, in <module>
    from pip._vendor import pkg_resources
  File "/usr/lib/python3.8/site-packages/pip/_vendor/pkg_resources/__init__.py", line 84, in <module>
    __import__('pip._vendor.packaging.requirements')
  File "/usr/lib/python3.8/site-packages/packaging/requirements.py", line 9, in <module>
    from pyparsing import stringStart, stringEnd, originalTextFor, ParseException
ModuleNotFoundError: No module named 'pyparsing'
```

So I tried to install `pyparsing`

```shell
python -m pip install pyparsing
```

And failed. `pyparsing` is needed to install `pyparsing`.

What the f\*\*k!

```shell
Traceback (most recent call last):
  File "/usr/lib/python3.8/runpy.py", line 193, in _run_module_as_main
    return _run_code(code, main_globals, None,
  File "/usr/lib/python3.8/runpy.py", line 86, in _run_code
    exec(code, run_globals)
  File "/usr/lib/python3.8/site-packages/pip/__main__.py", line 16, in <module>
    from pip._internal.main import main as _main  # isort:skip # noqa
  File "/usr/lib/python3.8/site-packages/pip/_internal/main.py", line 13, in <module>
    from pip._internal.cli.autocompletion import autocomplete
  File "/usr/lib/python3.8/site-packages/pip/_internal/cli/autocompletion.py", line 11, in <module>
    from pip._internal.cli.main_parser import create_main_parser
  File "/usr/lib/python3.8/site-packages/pip/_internal/cli/main_parser.py", line 7, in <module>
    from pip._internal.cli import cmdoptions
  File "/usr/lib/python3.8/site-packages/pip/_internal/cli/cmdoptions.py", line 28, in <module>
    from pip._internal.models.target_python import TargetPython
  File "/usr/lib/python3.8/site-packages/pip/_internal/models/target_python.py", line 4, in <module>
    from pip._internal.utils.misc import normalize_version_info
  File "/usr/lib/python3.8/site-packages/pip/_internal/utils/misc.py", line 19, in <module>
    from pip._vendor import pkg_resources
  File "/usr/lib/python3.8/site-packages/pip/_vendor/pkg_resources/__init__.py", line 84, in <module>
    __import__('pip._vendor.packaging.requirements')
  File "/usr/lib/python3.8/site-packages/packaging/requirements.py", line 9, in <module>
    from pyparsing import stringStart, stringEnd, originalTextFor, ParseException
ModuleNotFoundError: No module named 'pyparsing'
```

I also tried `pacman`

```shell
sudo pacman -Ss appdirs
```

```shell
extra/python-appdirs 1.4.3-5 [installed]
    A small Python module for determining appropriate platform-specific dirs, e.g. a "user data dir".
extra/python2-appdirs 1.4.3-5 [installed]
    A small Python module for determining appropriate platform-specific dirs, e.g. a "user data dir".
```

And I tried to upgrade pip like someone on forum.

```shell
pip install --upgrade pip
```

```shell
sh: /opt/jython/bin//pip: bad interpreter: /build/jython/pkg/jython/opt/jython/bin/jython: no such file or directory
Traceback (most recent call last):
  File "/usr/bin/pip", line 6, in <module>
    from pkg_resources import load_entry_point
  File "/usr/lib/python3.8/site-packages/pkg_resources/__init__.py", line 80, in <module>
    import appdirs
ModuleNotFoundError: No module named 'appdirs'
```

I also tried to reinstall all python packages like another guy on forum.

```shell
sudo pacman -Qqs python* > python.txt
```

```shell
sudo pacman -S - < python.txt
```

But all of these solutions did not work for me. After all these operations, I ran

```shell
yay -S cpupower-gui
```

again, and the same error appeared.

```shell
Traceback (most recent call last):
  File "/usr/bin/meson", line 6, in <module>
    from pkg_resources import load_entry_point
  File "/usr/lib/python3.8/site-packages/pkg_resources/__init__.py", line 80, in <module>
    import appdirs
ModuleNotFoundError: No module named 'appdirs'
```

Then I wanted to know if `appdirs` was really installed.

```shell
ls /usr/lib/python3.8/site-packages/
```

It turned out that `appdirs` had not been installed. `pacman` cheated me.

I downloaded `pyparsing` from Pypi and started to install it manually.

```shell
cd Downloads/
tar zxvf pyparsing-2.4.6.tar.gz
cd pyparsing-2.4.6/
sudo python setup.py install
```

```shell
Traceback (most recent call last):
  File "setup.py", line 5, in <module>
    from setuptools import setup
  File "/usr/lib/python3.8/site-packages/setuptools/__init__.py", line 17, in <module>
    import setuptools.version
  File "/usr/lib/python3.8/site-packages/setuptools/version.py", line 1, in <module>
    import pkg_resources
  File "/usr/lib/python3.8/site-packages/pkg_resources/__init__.py", line 80, in <module>
    import appdirs
ModuleNotFoundError: No module named 'appdirs'
[hxp@hxp-arch pyparsing-2.4.6]$ sudo python setup.py install
Traceback (most recent call last):
  File "setup.py", line 5, in <module>
    from setuptools import setup
  File "/usr/lib/python3.8/site-packages/setuptools/__init__.py", line 17, in <module>
    import setuptools.version
  File "/usr/lib/python3.8/site-packages/setuptools/version.py", line 1, in <module>
    import pkg_resources
  File "/usr/lib/python3.8/site-packages/pkg_resources/__init__.py", line 80, in <module>
    import appdirs
ModuleNotFoundError: No module named 'appdirs'
```

And install `pyparsing` required `appdir`

So I downloaded `appdirs` from Pypi

```shell
cd ..
tar zxvf appdirs-1.4.3.tar.gz
cd appdirs-1.4.3/
sudo python setup.py install
```

```shell
/usr/lib/python3.8/distutils/dist.py:274: UserWarning: Unknown distribution option: 'test_suite'
  warnings.warn(msg)
/usr/lib/python3.8/distutils/dist.py:274: UserWarning: Unknown distribution option: 'tests_require'
  warnings.warn(msg)
running install
running build
running build_py
running install_lib
copying build/lib/appdirs.py -> /usr/lib/python3.8/site-packages
byte-compiling /usr/lib/python3.8/site-packages/appdirs.py to appdirs.cpython-38.pyc
running install_egg_info
Writing /usr/lib/python3.8/site-packages/appdirs-1.4.3-py3.8.egg-info
```

`appdirs` installed successfully. Install `pyparing` again.

```shell
cd ..
cd pyparsing-2.4.6/
sudo python setup.py install
```

```shell
Traceback (most recent call last):
  File "setup.py", line 5, in <module>
    from setuptools import setup
  File "/usr/lib/python3.8/site-packages/setuptools/__init__.py", line 19, in <module>
    from setuptools.dist import Distribution, Feature
  File "/usr/lib/python3.8/site-packages/setuptools/dist.py", line 30, in <module>
    import ordered_set
ModuleNotFoundError: No module named 'ordered_set'
```

`ordered_set` was needed.

I tried to install `ordered_set` with `pip`

```shell
sudo python -m pip install ordered_set
```

And I got

```shell
ModuleNotFoundError: No module named 'pyparsing'
```

Install `orderes_set` require `pyparsing`. So I needed to install `pyparsing` first. And install `pyparsing` requires `ordered_set`

What the hell it was ???

I also downloaded `ordered_set` from Pypi.

```shell
cd ..
tar zxvf ordered-set-3.1.1.tar.gz
cd ordered-set-3.1.1/
sudo python setup.py install
```

```shell
Traceback (most recent call last):
  File "setup.py", line 1, in <module>
    from setuptools import setup
  File "/usr/lib/python3.8/site-packages/setuptools/__init__.py", line 17, in <module>
    import setuptools.version
  File "/usr/lib/python3.8/site-packages/setuptools/version.py", line 1, in <module>
    import pkg_resources
  File "/usr/lib/python3.8/site-packages/pkg_resources/__init__.py", line 84, in <module>
    __import__('packaging.requirements')
  File "/usr/lib/python3.8/site-packages/packaging/requirements.py", line 9, in <module>
    from pyparsing import stringStart, stringEnd, originalTextFor, ParseException
ModuleNotFoundError: No module named 'pyparsing'
```

And tried `pacman`

```shell
extra/python-pyparsing 2.4.6-1 [installed]
    General parsing module for Python
extra/python2-pyparsing 2.4.6-1 [installed]
    General parsing module for Python
community/python-dbus-signature-pyparsing 0.03-6
    A Parser for a D-Bus Signature
```

```shell
pacman -Ss ordered-set
```

```shell
extra/python-ordered-set 3.1.1-1 [installed]
    A MutableSet that remembers its order, so that every entry has an index
extra/python2-ordered-set 3.1.1-1 [installed]
    A MutableSet that remembers its order, so that every entry has an index
```

But no luck.

And then this idea came across:

```shell
cd ..
cp ordered-set-3.1.1/ordered_set.py pyparsing-2.4.6
cd pyparsing-2.4.6/
sudo python setup.py install
```

And it works! `pyparsing` installed successfully!

```shell
running install
running bdist_egg
running egg_info
writing pyparsing.egg-info/PKG-INFO
writing dependency_links to pyparsing.egg-info/dependency_links.txt
writing top-level names to pyparsing.egg-info/top_level.txt
reading manifest file 'pyparsing.egg-info/SOURCES.txt'
reading manifest template 'MANIFEST.in'
warning: no files found matching 'HowToUsePyparsing.rst'
warning: no files found matching 'pyparsingClassDiagram.*'
warning: no files found matching 'README.md'
warning: no files found matching 'modules.rst'
no previously-included directories found matching 'docs/_build/*'
writing manifest file 'pyparsing.egg-info/SOURCES.txt'
installing library code to build/bdist.linux-x86_64/egg
running install_lib
running build_py
creating build
creating build/lib
copying pyparsing.py -> build/lib
creating build/bdist.linux-x86_64
creating build/bdist.linux-x86_64/egg
copying build/lib/pyparsing.py -> build/bdist.linux-x86_64/egg
byte-compiling build/bdist.linux-x86_64/egg/pyparsing.py to pyparsing.cpython-38.pyc
creating build/bdist.linux-x86_64/egg/EGG-INFO
copying pyparsing.egg-info/PKG-INFO -> build/bdist.linux-x86_64/egg/EGG-INFO
copying pyparsing.egg-info/SOURCES.txt -> build/bdist.linux-x86_64/egg/EGG-INFO
copying pyparsing.egg-info/dependency_links.txt -> build/bdist.linux-x86_64/egg/EGG-INFO
copying pyparsing.egg-info/top_level.txt -> build/bdist.linux-x86_64/egg/EGG-INFO
zip_safe flag not set; analyzing archive contents...
__pycache__.pyparsing.cpython-38: module MAY be using inspect.getinnerframes
creating dist
creating 'dist/pyparsing-2.4.6-py3.8.egg' and adding 'build/bdist.linux-x86_64/egg' to it
removing 'build/bdist.linux-x86_64/egg' (and everything under it)
Processing pyparsing-2.4.6-py3.8.egg
creating /usr/lib/python3.8/site-packages/pyparsing-2.4.6-py3.8.egg
Extracting pyparsing-2.4.6-py3.8.egg to /usr/lib/python3.8/site-packages
Adding pyparsing 2.4.6 to easy-install.pth file

Installed /usr/lib/python3.8/site-packages/pyparsing-2.4.6-py3.8.egg
Processing dependencies for pyparsing==2.4.6
Finished processing dependencies for pyparsing==2.4.6
```

The next one was `ordered-set`

```shell
cd ..
cd ordered-set-3.1.1/
sudo python setup.py install
```

```shell
running install
running bdist_egg
running egg_info
writing ordered_set.egg-info/PKG-INFO
writing dependency_links to ordered_set.egg-info/dependency_links.txt
writing top-level names to ordered_set.egg-info/top_level.txt
reading manifest file 'ordered_set.egg-info/SOURCES.txt'
reading manifest template 'MANIFEST.in'
writing manifest file 'ordered_set.egg-info/SOURCES.txt'
installing library code to build/bdist.linux-x86_64/egg
running install_lib
running build_py
creating build
creating build/lib
copying ordered_set.py -> build/lib
creating build/bdist.linux-x86_64
creating build/bdist.linux-x86_64/egg
copying build/lib/ordered_set.py -> build/bdist.linux-x86_64/egg
byte-compiling build/bdist.linux-x86_64/egg/ordered_set.py to ordered_set.cpython-38.pyc
creating build/bdist.linux-x86_64/egg/EGG-INFO
copying ordered_set.egg-info/PKG-INFO -> build/bdist.linux-x86_64/egg/EGG-INFO
copying ordered_set.egg-info/SOURCES.txt -> build/bdist.linux-x86_64/egg/EGG-INFO
copying ordered_set.egg-info/dependency_links.txt -> build/bdist.linux-x86_64/egg/EGG-INFO
copying ordered_set.egg-info/top_level.txt -> build/bdist.linux-x86_64/egg/EGG-INFO
zip_safe flag not set; analyzing archive contents...
creating dist
creating 'dist/ordered_set-3.1.1-py3.8.egg' and adding 'build/bdist.linux-x86_64/egg' to it
removing 'build/bdist.linux-x86_64/egg' (and everything under it)
Processing ordered_set-3.1.1-py3.8.egg
Copying ordered_set-3.1.1-py3.8.egg to /usr/lib/python3.8/site-packages
Adding ordered-set 3.1.1 to easy-install.pth file

Installed /usr/lib/python3.8/site-packages/ordered_set-3.1.1-py3.8.egg
Processing dependencies for ordered-set==3.1.1
Finished processing dependencies for ordered-set==3.1.1
```

Great Success!

Finally, `pip` was able to run as usual.

```shell
yay -S cpupower-gui
```
