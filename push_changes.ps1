Set-Location "c:\Users\cytok\Desktop\VibeLesson\Cashflow app individual\cashflow_ai"
git add lib/features/cashflow/statement/pro_cash_flow_statement_screen.dart web/index.html 2>&1 | Out-File -FilePath "git_deploy.log"
git commit -m "Add TOTAL ENDING CASH section, account breakdown, Net Transfers, and fix text clipping in PDF export" 2>&1 | Out-File -FilePath "git_deploy.log" -Append
git push origin main 2>&1 | Out-File -FilePath "git_deploy.log" -Append
Get-Content "git_deploy.log"
