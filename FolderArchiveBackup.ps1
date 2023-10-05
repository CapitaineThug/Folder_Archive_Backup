#-------------------------------------------------------------------------------------------- 
# Auteur : Nicolas SCHMID (nicolas.schmid@studentfr.ch)
# Date : 19.09.2023
# Version : V4.0
# Description du script : Utilitaire de gestion de sauvegardes en archives d'un répertoire
# Paramètres: aucun​
#-------------------------------------------------------------------------------------------- ​

#Generated Form Function
function GenerateForm {

	################################################
	#Cette fonction va récupérer toues les fichiers
	# du répertoire sélectionnéen format ".zip" pour
	#les afficher dans la list-box
	################################################
	Function ScanBackup {
		$ExistingBackup = Get-ChildItem -Path $TB_SavePath.text | Sort-Object LastWriteTime -Descending
		$LB_ExistingSave.Items.clear()

		foreach ($backup in $ExistingBackup) {
			
			if (($backup.Extension) -eq "." + $TB_Extension.text) {

				#Init des variables
				$FileSize = [int] 0
				$FileUnit = ""

				#Le fichier s'exprime en PO (là ya vraiment un problème à par ça)
				if ($backup.length -ge 999999999999999) {
					#Calcul de la taille
					$FileSize = [INT][MATH]::Round( $backup.Length / 1PB)
					$FileUnit = "PO"
				}
				#Le fichier s'exprime en TO (faut pas abuser)
				elseif ($backup.length -ge 999999999999) {
					#Calcul de la taille
					$FileSize = [INT][MATH]::Round( $backup.Length / 1TB)
					$FileUnit = "TO"
				}

				#Le fichier s'exprime en GO
				elseif ($backup.length -ge 999999999) {
					#Calcul de la taille
					$FileSize = [INT][MATH]::Round( $backup.Length / 1GB)
					$FileUnit = "GO"
				}

				#Le fichier s'exprime en MO
				elseif ($backup.length -ge 999999) {
					#Calcul de la taille
					$FileSize = [INT][MATH]::Round( $backup.Length / 1MB)
					$FileUnit = "MO"
				}

				#Le fichier s'exprime en KO
				elseif ($backup.length -ge 999) {
					#Calcul de la taille
					$FileSize = [INT][MATH]::Round( $backup.Length / 1KB)
					$FileUnit = "KO"
				}
				#Default
				else {
					$FileSize = [INT] $backup.Length
					$FileUnit = "O"
				}

				#Ajouter la sauvegarde à la liste ainsi que sa taille dans la bonne unité
				$LB_ExistingSave.Items.Add("$backup | $FileSize $FileUnit")
			}

		} 
 }
	################################################
	#Cette fonction va créer la sauvegarde en fichier
	#".zip" dans le répertoire sélectionné
	################################################
	Function BackupNow {
		#Vérification que les chemins d'accès sont renseignée et valides
		if (("" -ne $TB_SavePath.text) -and ("" -ne $TB_ToSavePath.text)) {
			if ((Test-path -Path $TB_SavePath.text) -and (Test-Path -path $TB_ToSavePath.text)) {
				#Variables
				$CurrentDate = Get-Date -Format "dd/MM/yyyy"
				$CurrentHour = Get-Date -Format "HH"
				$CurrentMinute = Get-Date -Format "mm"

				$CurrentSurname = $TB_SaveName.text
				$Extension = $TB_Extension.text

				$ArchiveCompressName = $CurrentDate + "_" + $CurrentHour + "h" + $CurrentMinute + "m_" + $CurrentSurname + ".zip"
				$ArchiveRealName = $TB_SavePath.text + "\" + $CurrentDate + "_" + $CurrentHour + "h" + $CurrentMinute + "m_" + $CurrentSurname + "." + $Extension
				$ArchiveFullPath = $TB_SavePath.text + "\" + $ArchiveCompressName

				$InvalidChar = [System.IO.Path]::GetInvalidFileNameChars()

				#le nom et l'extension ne doivent pas être nulles
				if (("" -ne $CurrentSurname) -and ("" -ne $Extension)) {
					#Le nom et l'extension doivent être valides
					if (($CurrentSurname -notmatch "[$InvalidChar]") -and ($Extension -notmatch "[$InvalidChar]")) {						
							
						#Le fichier ne doit pas exister 2 fois
						if (Test-Path -Path $ArchiveFullPath -PathType Leaf) {
		
							#Log
							$RTB_Output.AppendText("La sauvegarde suivante existe déjà ! : " + $ArchiveName + [char]13 + [char]10)
					
						}
						else {
							#Variables
							$StartTime = Get-Date
		
							#Barre de progression verte
							$PGB_CurrentSave.Value = 100
		
							$ArchiveBackup = @{
								Path             = $TB_ToSavePath.text
								CompressionLevel = "Fastest"
								DestinationPath  = $ArchiveFullPath
			
							}
			
							#Launch !!
							Compress-Archive @ArchiveBackup		
		
	
							$PGB_CurrentSave.Value = 0
							$ElapsedTime = (Get-Date) - $StartTime
							$ElapsedSeconds = [math]::Round($ElapsedTime.TotalSeconds, 3)

							#Renommer l'archive une fois terminé (impossible de compresser dans une extension personnalisée...)
							Rename-Item -Path $ArchiveFullPath -NewName ($ArchiveRealName)

							#Rafraichir les sauvegardes existantes
							ScanBackup
		
							#Log
							$RTB_Output.AppendText("Sauvegarde effectuée : " + $ArchiveName + " Temps d'exécution : " + $ElapsedSeconds + "s" + [char]13 + [char]10)
						}
						
					}
					else {
						#Log
						$RTB_Output.AppendText("Le surnom et/ou l'extension du fichier n'est/sont pas valide/s !" + [char]13 + [char]10)
					}

				}
				else {
					#Log
					$RTB_Output.AppendText("Le surnom et/ou l'extension est/sont vides !" + [char]13 + [char]10)
				}
			}
			else {
				#Log
				$RTB_Output.AppendText("Un ou plusieurs chemins d'accès renseignés ne sont pas valides !" + [char]13 + [char]10)

			}
		}
		else { 
			#Log
			$RTB_Output.AppendText("Veuillez renseigner des chemin d'accès !" + [char]13 + [char]10)

		}
	}
	################################################
	#Cette fonction va effacer les sauvegardes
	#sélectionnées
	################################################
	Function EreaseBackup {
		#Une ou plusieurs sauvegardes doivent être sélectionnées
		if ($null -ne $LB_ExistingSave.SelectedItem) {
			#Fenêtre de confirmation
			$Confirmation = [System.Windows.Forms.MessageBox]::Show("La/Les sauvegarde/s va/vont être effacée/s !", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

			if ($Confirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
				# Obtenez la liste des sauvegardes sélectionnées
				$SelectedBackups = $LB_ExistingSave.SelectedItems

				# Parcourez la liste des sauvegardes sélectionnées et supprimez-les
				foreach ($backup in $SelectedBackups) {
					#Séparation de la partie nom du fichier de la partie taille (je sais, pas très malin mais bon)
					$NomEtTaille = $backup.Split("|")

					$BackupFullPath = $TB_SavePath.text + "\" + $NomEtTaille[0].trim()
					Remove-Item -Path $BackupFullPath -Force
				}

				# Rafraîchir les sauvegardes après suppression
				ScanBackup
			}
  }
		else {
			#Log
			$RTB_Output.AppendText("Vous devez sélectionner au minimum 1 sauvegarde pour l'effacer !" + [char]13 + [char]10) 
  }


	}

	

	#region Import the Assemblies
	[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
	[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
	#endregion

	#region Generated Form Objects
	$F_Main = New-Object System.Windows.Forms.Form
	$RTB_Output = New-Object System.Windows.Forms.RichTextBox
	$GB_Suppression = New-Object System.Windows.Forms.GroupBox
	$LB_ExistingSave = New-Object System.Windows.Forms.ListBox
	$BT_EreaseSave = New-Object System.Windows.Forms.Button
	$GB_Sauvegarde = New-Object System.Windows.Forms.GroupBox
	$PGB_CurrentSave = New-Object System.Windows.Forms.ProgressBar
	$BT_SaveNow = New-Object System.Windows.Forms.Button
	$GB_Global = New-Object System.Windows.Forms.GroupBox
	$TB_Extension = New-Object System.Windows.Forms.TextBox
	$TB_SaveName = New-Object System.Windows.Forms.TextBox
	$L_SaveName = New-Object System.Windows.Forms.Label
	$L_ToSavePath = New-Object System.Windows.Forms.Label
	$L_SavePath = New-Object System.Windows.Forms.Label
	$TB_SavePath = New-Object System.Windows.Forms.TextBox
	$TB_ToSavePath = New-Object System.Windows.Forms.TextBox
	$BT_Browse_ToSavePath = New-Object System.Windows.Forms.Button
	$BT_Browse_SavePath = New-Object System.Windows.Forms.Button
	$saveFileDialog1 = New-Object System.Windows.Forms.SaveFileDialog
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
	#endregion Generated Form Objects

	#----------------------------------------------
	#Generated Event Script Blocks
	#----------------------------------------------
	#Provide Custom Code for events specified in PrimalForms.
	$BT_Browse_ToSavePath_OnClick = 
	{
		#Ouverture d'une boite de dialogue pour renseigner un path dans la text box
		$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
		$FolderBrowser.SelectedPath = $PSScriptRoot
		$FolderBrowser.ShowDialog()
		$TB_ToSavePath.Text = $FolderBrowser.SelectedPath

		#Log
		$RTB_Output.AppendText("Dossier à sauvegarder : " + $TB_ToSavePath.Text + [char]13 + [char]10)

	}

	$handler_TB_SavePath_TextChanged = 
	{
		#Rafraichir la liste des sauvegardes
		ScanBackup

	}

	$handler_GB_Global_Enter = 
	{
		#TODO: Place custom script here

	}

	$BT_EreaseSave_OnClick =
	{
		#Effacer les sauvegardes
		EreaseBackup
	}

	$BT_SaveNow_OnClick = 
	{
		#Lancer une sauvegarde
		BackupNow

	}

	$BT_Browse_SavePath_OnClick = 
	{
		#Ouverture d'une boite de dialogue pour renseigner un path dans la text box
		$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
		$FolderBrowser.SelectedPath = $PSScriptRoot
		$FolderBrowser.ShowDialog()
		$TB_SavePath.Text = $FolderBrowser.SelectedPath

		#Log
		$RTB_Output.AppendText("Dossier de destination des sauvegardes : " + $TB_SavePath.Text + [char]13 + [char]10)

	}

	$OnLoadForm_StateCorrection =
	{ #Correct the initial state of the form to prevent the .Net maximized form issue
		$F_Main.WindowState = $InitialFormWindowState
	}

	$TB_Extension_TextChanged = {
		#Un ptit refresh quand on change l'extension
		ScanBackup
	}

	#----------------------------------------------
	#region Generated Form Code
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 531
	$System_Drawing_Size.Width = 1041
	$F_Main.ClientSize = $System_Drawing_Size
	$F_Main.DataBindings.DefaultDataSourceUpdateMode = 0
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 570
	$System_Drawing_Size.Width = 1057
	$F_Main.MinimumSize = $System_Drawing_Size
	$F_Main.Name = "F_Main"
	$F_Main.Text = "Gestionnaire de sauvegarde"
    
	$RTB_Output.Anchor = 15
	$RTB_Output.BackColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
	$RTB_Output.DataBindings.DefaultDataSourceUpdateMode = 0
	$RTB_Output.Font = New-Object System.Drawing.Font("Courier New", 8.25, 0, 3, 1)
	$RTB_Output.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 255, 127)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 12
	$System_Drawing_Point.Y = 349
	$RTB_Output.Location = $System_Drawing_Point
	$RTB_Output.Name = "RTB_Output"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 170
	$System_Drawing_Size.Width = 1017
	$RTB_Output.Size = $System_Drawing_Size
	$RTB_Output.TabIndex = 3
	$RTB_Output.Text = "Gestionnaire de sauvegarde - output|" + [char]13 + [char]10 + "-----------------------------------|" + [char]13 + [char]10
    
	$F_Main.Controls.Add($RTB_Output)

	$GB_Suppression.Anchor = 13
	$GB_Suppression.AutoSizeMode = 0

	$GB_Suppression.DataBindings.DefaultDataSourceUpdateMode = 0
	$GB_Suppression.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 14.25, 0, 3, 1)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 686
	$System_Drawing_Point.Y = 12
	$GB_Suppression.Location = $System_Drawing_Point
	$GB_Suppression.Name = "GB_Suppression"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 331
	$System_Drawing_Size.Width = 343
	$GB_Suppression.Size = $System_Drawing_Size
	$GB_Suppression.TabIndex = 2
	$GB_Suppression.TabStop = $False
	$GB_Suppression.Text = "Supression de sauvegarde"

	$F_Main.Controls.Add($GB_Suppression)
	$LB_ExistingSave.Anchor = 13
	$LB_ExistingSave.DataBindings.DefaultDataSourceUpdateMode = 0
	$LB_ExistingSave.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8.25, 0, 3, 1)
	$LB_ExistingSave.FormattingEnabled = $True
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 25
	$System_Drawing_Point.Y = 104
	$LB_ExistingSave.Location = $System_Drawing_Point
	$LB_ExistingSave.Name = "LB_ExistingSave"
	$LB_ExistingSave.SelectionMode = 2
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 186
	$System_Drawing_Size.Width = 292
	$LB_ExistingSave.Size = $System_Drawing_Size
	$LB_ExistingSave.TabIndex = 2

	$GB_Suppression.Controls.Add($LB_ExistingSave)

	$BT_EreaseSave.Anchor = 13
	$BT_EreaseSave.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 42, 42)
	
	$BT_EreaseSave.DataBindings.DefaultDataSourceUpdateMode = 0
	$BT_EreaseSave.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 25
	$System_Drawing_Point.Y = 35
	$BT_EreaseSave.Location = $System_Drawing_Point
	$BT_EreaseSave.Name = "BT_EreaseSave"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 63
	$System_Drawing_Size.Width = 292
	$BT_EreaseSave.Size = $System_Drawing_Size
	$BT_EreaseSave.TabIndex = 0
	$BT_EreaseSave.Text = "Effacer la sauvegarde sélectionnée"
	$BT_EreaseSave.UseVisualStyleBackColor = $False
	$BT_EreaseSave.add_Click($BT_EreaseSave_OnClick)
	$GB_Suppression.Controls.Add($BT_EreaseSave)


	$GB_Sauvegarde.AutoSizeMode = 0

	$GB_Sauvegarde.DataBindings.DefaultDataSourceUpdateMode = 0
	$GB_Sauvegarde.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 14.25, 0, 3, 1)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 12
	$System_Drawing_Point.Y = 239
	$GB_Sauvegarde.Location = $System_Drawing_Point
	$GB_Sauvegarde.Name = "GB_Sauvegarde"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 104
	$System_Drawing_Size.Width = 668
	$GB_Sauvegarde.Size = $System_Drawing_Size
	$GB_Sauvegarde.TabIndex = 1
	$GB_Sauvegarde.TabStop = $False
	$GB_Sauvegarde.Text = "Création de sauvegarde"

	$F_Main.Controls.Add($GB_Sauvegarde)
	$PGB_CurrentSave.DataBindings.DefaultDataSourceUpdateMode = 0
	$PGB_CurrentSave.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 255, 127)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 289
	$System_Drawing_Point.Y = 43
	$PGB_CurrentSave.Location = $System_Drawing_Point
	$PGB_CurrentSave.Name = "PGB_CurrentSave"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 45
	$System_Drawing_Size.Width = 363
	$PGB_CurrentSave.Size = $System_Drawing_Size
	$PGB_CurrentSave.Style = 1
	$PGB_CurrentSave.TabIndex = 1

	$GB_Sauvegarde.Controls.Add($PGB_CurrentSave)


	$BT_SaveNow.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 6
	$System_Drawing_Point.Y = 43
	$BT_SaveNow.Location = $System_Drawing_Point
	$BT_SaveNow.Name = "BT_SaveNow"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 45
	$System_Drawing_Size.Width = 277
	$BT_SaveNow.Size = $System_Drawing_Size
	$BT_SaveNow.TabIndex = 0
	$BT_SaveNow.Text = "Sauvegarder Maintenant"
	$BT_SaveNow.UseVisualStyleBackColor = $True
	$BT_SaveNow.add_Click($BT_SaveNow_OnClick)

	$GB_Sauvegarde.Controls.Add($BT_SaveNow)


	$GB_Global.AutoSizeMode = 0

	$GB_Global.DataBindings.DefaultDataSourceUpdateMode = 0
	$GB_Global.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 14.25, 0, 3, 1)
	$GB_Global.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 12
	$System_Drawing_Point.Y = 12
	$GB_Global.Location = $System_Drawing_Point
	$GB_Global.Name = "GB_Global"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 221
	$System_Drawing_Size.Width = 668
	$GB_Global.Size = $System_Drawing_Size
	$GB_Global.TabIndex = 0
	$GB_Global.TabStop = $False
	$GB_Global.Text = "Paramètres globaux"
	$GB_Global.add_Enter($handler_GB_Global_Enter)

	$F_Main.Controls.Add($GB_Global)
	$TB_Extension.DataBindings.DefaultDataSourceUpdateMode = 0
	$TB_Extension.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8.25, 0, 3, 0)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 516
	$System_Drawing_Point.Y = 180
	$TB_Extension.Location = $System_Drawing_Point
	$TB_Extension.Name = "TB_Extension"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 120
	$TB_Extension.Size = $System_Drawing_Size
	$TB_Extension.TabIndex = 8
	$TB_Extension.add_TextChanged($TB_Extension_TextChanged)
	$TB_Extension.text = "zip"

	$GB_Global.Controls.Add($TB_Extension)

	$TB_SaveName.DataBindings.DefaultDataSourceUpdateMode = 0
	$TB_SaveName.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8.25, 0, 3, 1)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 270
	$System_Drawing_Point.Y = 180
	$TB_SaveName.Location = $System_Drawing_Point
	$TB_SaveName.Name = "TB_SaveName"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 231
	$TB_SaveName.Size = $System_Drawing_Size
	$TB_SaveName.TabIndex = 7
	$TB_Savename.text = "FolderBackup"

	$GB_Global.Controls.Add($TB_SaveName)

	$L_SaveName.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 21
	$System_Drawing_Point.Y = 175
	$L_SaveName.Location = $System_Drawing_Point
	$L_SaveName.Name = "L_SaveName"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 30
	$System_Drawing_Size.Width = 242
	$L_SaveName.Size = $System_Drawing_Size
	$L_SaveName.TabIndex = 6
	$L_SaveName.Text = "Nom / Extension"
	$L_SaveName.add_Click($handler_L_SaveName_Click)

	$GB_Global.Controls.Add($L_SaveName)

	$L_ToSavePath.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 21
	$System_Drawing_Point.Y = 113
	$L_ToSavePath.Location = $System_Drawing_Point
	$L_ToSavePath.Name = "L_ToSavePath"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 25
	$System_Drawing_Size.Width = 243
	$L_ToSavePath.Size = $System_Drawing_Size
	$L_ToSavePath.TabIndex = 5
	$L_ToSavePath.Text = "Location à sauvegarder"


	$GB_Global.Controls.Add($L_ToSavePath)

	$L_SavePath.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 21
	$System_Drawing_Point.Y = 47
	$L_SavePath.Location = $System_Drawing_Point
	$L_SavePath.Name = "L_SavePath"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 29
	$System_Drawing_Size.Width = 243
	$L_SavePath.Size = $System_Drawing_Size
	$L_SavePath.TabIndex = 4
	$L_SavePath.Text = "Location des sauvegardes"

	$GB_Global.Controls.Add($L_SavePath)

	$TB_SavePath.DataBindings.DefaultDataSourceUpdateMode = 0
	$TB_SavePath.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8.25, 0, 3, 1)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 270
	$System_Drawing_Point.Y = 44
	$TB_SavePath.Location = $System_Drawing_Point
	$TB_SavePath.Name = "TB_SavePath"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 231
	$TB_SavePath.Size = $System_Drawing_Size
	$TB_SavePath.TabIndex = 3
	$TB_SavePath.add_TextChanged($handler_TB_SavePath_TextChanged)
	$TB_SavePath.Text = ""

	$GB_Global.Controls.Add($TB_SavePath)

	$TB_ToSavePath.DataBindings.DefaultDataSourceUpdateMode = 0
	$TB_ToSavePath.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8.25, 0, 3, 1)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 270
	$System_Drawing_Point.Y = 110
	$TB_ToSavePath.Location = $System_Drawing_Point
	$TB_ToSavePath.Name = "TB_ToSavePath"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 231
	$TB_ToSavePath.Size = $System_Drawing_Size
	$TB_ToSavePath.TabIndex = 2
	$TB_ToSavePath.text = ""

	$GB_Global.Controls.Add($TB_ToSavePath)


	$BT_Browse_ToSavePath.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 516
	$System_Drawing_Point.Y = 104
	$BT_Browse_ToSavePath.Location = $System_Drawing_Point
	$BT_Browse_ToSavePath.Name = "BT_Browse_ToSavePath"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 42
	$System_Drawing_Size.Width = 119
	$BT_Browse_ToSavePath.Size = $System_Drawing_Size
	$BT_Browse_ToSavePath.TabIndex = 1
	$BT_Browse_ToSavePath.Text = "Parcourir"
	$BT_Browse_ToSavePath.UseVisualStyleBackColor = $True
	$BT_Browse_ToSavePath.add_Click($BT_Browse_ToSavePath_OnClick)

	$GB_Global.Controls.Add($BT_Browse_ToSavePath)


	$BT_Browse_SavePath.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 516
	$System_Drawing_Point.Y = 40
	$BT_Browse_SavePath.Location = $System_Drawing_Point
	$BT_Browse_SavePath.Name = "BT_Browse_SavePath"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 39
	$System_Drawing_Size.Width = 120
	$BT_Browse_SavePath.Size = $System_Drawing_Size
	$BT_Browse_SavePath.TabIndex = 0
	$BT_Browse_SavePath.Text = "Parcourir"
	$BT_Browse_SavePath.UseVisualStyleBackColor = $True
	$BT_Browse_SavePath.add_Click($BT_Browse_SavePath_OnClick)

	$GB_Global.Controls.Add($BT_Browse_SavePath)


	$saveFileDialog1.CreatePrompt = $True
	$saveFileDialog1.ShowHelp = $True

	#endregion Generated Form Code

	#Save the initial state of the form
	$InitialFormWindowState = $F_Main.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$F_Main.add_Load($OnLoadForm_StateCorrection)
	#Show the Form
	$F_Main.ShowDialog() | Out-Null

} #End Function

#Call the Function
GenerateForm
