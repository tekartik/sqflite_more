# sqflite_server

Sqflite server component

## Getting Started

### Run the sqflite_server_app

Run the sqflite server app on your device or emulator

    cd sqflite_server_app
    flutter run
    
If running on android make sure to forward the tcp port

    adb forward tcp:8501 tcp:8501
    
### Run some tests

Once the server is started (it does not start automatically the first time),
you can run your test

    cd sqflite_test
    flutter test
   
    
## Use

### Use in your app

````yaml
dependencies:
  sqflite_common_server:
    git:
      url: https://github.com/tekartik/sqflite_more
      path: sqflite_common_server
    version: '>=0.3.0'
````

Look at the sqflite_test package which has some unit tests
