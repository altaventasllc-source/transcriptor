on run
	set msg to "Se eliminaran:" & return & return & "  - Carpeta ~/Transcriptor (proyecto, modelos, uploads)" & return & "  - Transcriptor.app del Escritorio" & return & "  - Instalador_Transcriptor.app del Escritorio" & return & "  - Desinstalador_Transcriptor.app del Escritorio" & return & "  - Cache del modelo de IA (~1.5 GB)" & return & return & "NO se eliminaran (pueden usarlos otras apps):" & return & "  - Homebrew, Python, FFmpeg, Deno"

	set theResponse to display dialog msg buttons {"Cancelar", "Desinstalar"} default button "Cancelar" cancel button "Cancelar" with icon caution with title "Desinstalar Transcriptor"

	if button returned of theResponse is "Desinstalar" then
		try
			do shell script "lsof -ti:5050 | xargs kill 2>/dev/null; true"
			do shell script "rm -rf ~/Transcriptor"
			do shell script "rm -rf ~/Desktop/Transcriptor.app"
			do shell script "rm -rf ~/Desktop/Instalador_Transcriptor.app"
			do shell script "rm -rf ~/.cache/huggingface/hub/models--Systran--faster-whisper-medium 2>/dev/null; true"

			display dialog "Transcriptor desinstalado correctamente." & return & return & "Puedes arrastrar Desinstalador_Transcriptor.app a la Papelera cuando quieras." buttons {"OK"} default button "OK" with icon note with title "Desinstalar Transcriptor"
		on error errMsg
			display dialog "Error durante la desinstalacion:" & return & return & errMsg buttons {"OK"} default button "OK" with icon stop with title "Desinstalar Transcriptor"
		end try
	end if
end run
