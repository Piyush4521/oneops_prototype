Start-Process node -ArgumentList 'src/server.js' -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
Start-Sleep -Seconds 1
node test/workflow.test.mjs
