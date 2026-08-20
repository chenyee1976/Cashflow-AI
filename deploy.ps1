Set-Location "c:\Users\cytok\Desktop\VibeLesson\Cashflow app individual\cashflow_ai"
git add lib/features/cashflow/statement/pro_cash_flow_statement_screen.dart web/index.html build.sh 2>&1 | Out-File -FilePath "deploy_log.txt" -Append
git commit -m "Fix PDF export: printable HTML window for reliable PC and mobile downloads" 2>&1 | Out-File -FilePath "deploy_log.txt" -Append
git push origin main 2>&1 | Out-File -FilePath "deploy_log.txt" -Append
Get-Content "deploy_log.txt"
