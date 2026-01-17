# 第一阶段：构建前端  
FROM node:20-alpine AS frontend-builder  
  
WORKDIR /app/frontend  
COPY frontend/package*.json ./  
RUN npm install  
COPY frontend/ .  
  
# Set Node.js options to fix crypto.hash issue  
ENV NODE_OPTIONS="--openssl-legacy-provider"  
RUN npm run build  
  
# 第二阶段：运行后端  
FROM python:3.11-slim  
  
WORKDIR /app  
  
ENV PYTHONDONTWRITEBYTECODE=1 \  
    PYTHONUNBUFFERED=1  
  
# 安装 Python 依赖  
COPY requirements.txt .  
RUN apt-get update && apt-get install -y --no-install-recommends \  
    gcc \  
    && pip install --no-cache-dir -r requirements.txt \  
    && apt-get purge -y gcc \  
    && apt-get autoremove -y \  
    && rm -rf /var/lib/apt/lists/*  
  
# 复制后端代码  
COPY main.py .  
COPY core ./core  
COPY util ./util  
  
# 从前端构建阶段复制静态文件  
COPY --from=frontend-builder /app/frontend/dist ./static  
  
# 创建数据目录  
RUN mkdir -p ./data  
  
# 声明数据卷  
VOLUME ["/app/data"]  
  
# 启动服务  
CMD ["python", "-u", "main.py"]
