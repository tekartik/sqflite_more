## 0.2.4

* `connectClientPort()` (and so `testMain`) runs `adb forward` again when no
  `SQFLITE_SERVER_URL` / `SQFLITE_SERVER_PORT` is declared (never run since
  the null safety migration).
* `close()` forgets the client: a closed context connects again.
