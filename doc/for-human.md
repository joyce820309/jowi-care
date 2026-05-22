在 VS Code 底部點擊 Terminal 標籤（或按 Ctrl+`）
開一個新終端，輸入：
```
$env:Path += ";C:\flutter\bin"
flutter run -d chrome
```
啟動成功後，在那個終端視窗按 r 就能 Hot Reload