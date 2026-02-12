# Docker環境でRails/postgreSQLを動かすチュートリアル（Draft版）


## 操作手順

### ステップ0(.envファイルの設置)
.env.exampleファイルを元に、.envファイルを作成（データベース情報設定）

### ステップ1
```bash:bash
# Dockerイメージをビルド
docker-compose build

# Railsアプリケーションを新規作成（既存のファイルをスキップ）
docker-compose run --rm --no-deps web rails new . --force --database=postgresql --skip-bundle

# 権限を修正（重要！）
sudo chown -R $USER:$USER .
```

### ステップ2
```yml:database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  host: <%= ENV['DATABASE_HOST'] || 'db' %>
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: <%= ENV['POSTGRES_DB'] %>

test:
  <<: *default
  database: myapp_test

production:
  <<: *default
  database: myapp_production
  username: myapp
  password: <%= ENV["MYAPP_DATABASE_PASSWORD"] %>
```

### ステップ3
```bash:bash
# Gemのインストール
docker-compose run --rm web bundle install

# 権限を再度修正
sudo chown -R $USER:$USER .
```

### ステップ4：エラー発生→docker-compose.ymlとDockerfile修正
```yml:docker-compose.yml
services:
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"

  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b '0.0.0.0'"
    volumes:
      - .:/myapp
      - bundle_cache:/bundle  # 追加: bundleキャッシュ用ボリューム
    ports:
      - "3000:3000"
    depends_on:
      - db
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      DATABASE_HOST: db
      BUNDLE_PATH: /bundle  # 追加: bundlerのパスを指定
    user: "${UID}:${GID}"
    stdin_open: true
    tty: true

volumes:
  postgres_data:
  bundle_cache:  # 追加: bundleキャッシュ用ボリューム
```

```Dockerfile
FROM ruby:3.2

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install -y nodejs postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /myapp

# bundleディレクトリを作成（削除または修正）
RUN mkdir -p /bundle && chmod 777 /bundle

# Gemfileをコピー（この時点ではbundle installしない）
COPY Gemfile* ./

# エントリーポイントスクリプトをコピー
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

# デフォルトコマンド
CMD ["rails", "server", "-b", "0.0.0.0"]
```

### ステップ5
```bash:bash
# 既存のコンテナとボリュームを削除
docker-compose down -v

# イメージを再ビルド
docker-compose build --no-cache

# bundle installを実行
docker-compose run --rm web bundle install

# 権限を確認（必要に応じて）
sudo chown -R $USER:$USER .

# データベースを作成
docker-compose run --rm web bin/rails db:create
docker-compose run --rm web bin/rails db:migrate

# アプリケーションを起動
docker-compose up -d
```
