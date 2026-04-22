on run
	set tempScript to "/tmp/transcriptor_install.command"
	do shell script "curl -fsSL https://raw.githubusercontent.com/altaventasllc-source/transcriptor/main/scripts/install.sh -o " & quoted form of tempScript & " && chmod +x " & quoted form of tempScript
	do shell script "open -a Terminal " & quoted form of tempScript
end run
