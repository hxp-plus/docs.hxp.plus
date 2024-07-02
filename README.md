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
docker run -p 8001:8000 -v $PWD:/docs mkdocs
```
