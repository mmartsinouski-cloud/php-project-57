FROM php:8.4-cli

# 1. Установка системных зависимостей и Node.js
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    curl \
    gnupg \
    ca-certificates \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x bookworm main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 2. Установка PHP расширений
RUN docker-php-ext-install pdo pdo_pgsql zip

# 3. Установка Composer через официальный образ (это быстрее и надежнее)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# 4. Копирование файлов и установка зависимостей
COPY . .

# Если package-lock.json нет в репозитории, замените npm ci на npm install
RUN composer install --no-interaction --prefer-dist
RUN npm install && npm run build

# 5. Подготовка базы данных
RUN touch database/database.sqlite

# 6. Запуск (добавлен дефолтный PORT, если он не передан извне)
ENV PORT=8000
CMD ["bash", "-c", "php artisan migrate:refresh --seed --force && php artisan serve --host=0.0.0.0 --port=$PORT"]
