herokusample
============
https://obscure-spire-5224.herokuapp.com/

HerokuからSalesforceにアクセスしてCRUD操作するサンプル。

Features
------------
* 取引先責任者(Contact)のEmailでログイン
* Emailが一致するContactがなければinsert
* Contactの項目を編集
* Contactの子オブジェクト(ContactItem__c)を追加、編集、削除

Herokuがgrunt_type=passwordで認証するので、アカウントは1つだけ。

Usage
------------

### bundle install

```bash
bundle install --path vendor/bundle
```

### Deploy

src/email.unfiled$public/ContactToken.email のURLを自分のアプリケーションのURLに書き換える。

```
https://obscure-spire-5224.herokuapp.com/login/{!ContactLogin__c.Name}
```

デプロイにはmetaforceが使えます。

```bash
bundle exec metaforce deploy ./src
```

### ConnectedApp

SalesforceにログインしてConnectedApp(接続アプリケーション)を作成。

* App Name: 任意
* API Name: 任意
* Contact Email: 任意
* Enable OAuth Settings: チェックをつける
* Callback URL: any URL ex) http://localhost
* Selected OAuth Scopes: Access and manage your data (api)

API 29.0で対応したと書いてあるのに何故かretrieveもdeployもできない。salesforce_antを使ってもできない。

### Environment variables

以下の環境変数を設定。.envに書いておけばforemanが読み込んでくれる。

```bash
SALESFORCE_USERNAME="username"
SALESFORCE_PASSWORD="password"
SALESFORCE_SECURITY_TOKEN="security_token"
SALESFORCE_CLIENT_ID="client_id_of_connected_app"
SALESFORCE_CLIENT_SECRET="client_secret_of_connected_app"

SALESFORCE_HOST=login.salesforce.com # or test.salesforce.com

RACK_SESSION_SECRET="any_string"
```

### Run app

```bash
PORT=3000 bundle exec foreman start
```
