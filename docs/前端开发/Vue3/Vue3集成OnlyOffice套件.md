## 使用 docker 临时部署 onlyoffice 的 documentserver

在安装 docker 的节点 `ubuntu.hxp.lan` 上运行：

```
docker run -it --rm -p 8701:80 -e ALLOW_PRIVATE_IP_ADDRESS=true -e JWT_ENABLED=false onlyoffice/documentserver
```

部署完成后访问 `http://ubuntu.hxp.lan:8701/welcome/` 验证。

## 参考资料

https://blog.bszhct.com/2022/08/15/onlyoffice-quick-start/

https://juejin.cn/post/7291096702021271586
