# docs.hxp.plus

hxp 的文档库

## 如何编写

参考：<https://squidfunk.github.io/mkdocs-material/reference/>

## 构建容器镜像

```bash
docker build -t mkdocs .
```

## 运行

```
docker run --rm -it -v ${PWD}:/docs -p8001:8000 mkdocs
```
