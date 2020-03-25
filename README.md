# S2I hugo golang

## Build go hugo s2i image

1. Choose a name 

```
export S2INAME="s2i-hugo-go"
```

2. Build image

```
oc new-build centos/s2i-base-centos7~https://github.com/ALASPEDRO/s2i-hugo-golang --strategy docker --name $S2INAME
```
