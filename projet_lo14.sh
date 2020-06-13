#!/bin/bash
#Le script doit être situé dans le répertoire root de l'utilisateur pour l'instant
#variables
journal="$HOME/synjournal.txt"
ArbreA="$HOME/synchroniseur/A"
ArbreB="$HOME/synchroniseur/B"

#Status de la synchronisation
Esync="false";

#fonction du synchronisation sur le journal
function Jsync {
if [ $Esync = true ]
then
	#affichage de la date de synchronisation
	date
	#affichage du chemin absolu du fichier dans le journal
	find ./ -name $fichier >> $journal
	#affichage des droits, nom, date, propriétaire, groupe, le type et taille du fichier
	ls -l >> $journal
else
	echo "La synchronisation pour le fichier $fichier à échouée"
fi
	
}

#fonction pour gérer les conflits suite à la synchronisation
function lstcft {
if [ $conflit -ge 1 ]
then
	echo "Des conflits ont été détectés, voici la liste des fichiers concernés"
	cat listcft.txt
	echo "Choisissez les mesures à prendre:"
	echo "1) Afficher les différences entre les fichiers?"
	echo "2) Supprimer les fichiers concernés?"
	echo "3) ne rien faire"
	read choix
	case $choix in
		1) echo ""
		   diff $fichierA $fichierB -s
		   ;;
		2) echo ""
		   echo "La suppression des fichiers va commencer"
		   ;;
		3) echo ""
		   echo "Aucune modification ne sera apportée aux fichiers"
		   exit 1
		   ;;
		*) echo "Désolé, veuillez choisir les options 1, 2 ou 3"
                   lstcft
                   ;;
	esac

fi
}

#fonction du synchroniseur
function prmain {
#Utilisation d'un case pour tester les différentes possibilités sur les répertoires / copier les fichiers entre le 2 répertoires

for fichierA in $ArbreA/*
do
  echo "Affichage des fichiers de l'arbre A"
  if [ -f "$fichierA" ]
  then
  	basename $fichierA
  fi
  if [ -d "$fichierA" ]
  then
  	echo "$fichierA est un répertoire"
  fi
  for fichierB in $ArbreB/*
	do
	echo "Affichage des fichiers de l'arbre B"
	if [ -f "$fichierB" ]
  	then
  		basename $fichierB
  	fi
  	if [ -d "$fichierB" ]
  	then
  		echo "$fichierB est un répertoire"
  	fi

  case $fichierA in
	0)
	#if [ -d "$fichierA"] && [ -f "$fichierB" ] || [ -f "$fichierA" ] && [ -d "$fichierB" ]
	if [ -d "$fichierA" -a -f "$fichierB" ] || [ -f "$fichierA" -a -d "$fichierB" ]
	then
		echo "Conflit entre $fichierA et $fichierB"
		let conflit++
		touch $HOME/listcft.txt

		basename $fichierA >> listcft.txt
		basename $fichierB >> listcft.txt
		
	fi
	;;
	1)
	if [ -d "$fichierA" ] && [ -d "$fichierB" ]
	then
		echo "$fichierA et $fichierB sont des répertoires"
		prmain
	
	fi
	;;
	2)
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		echo "Synchronisation possible"
		Jsync
		
	fi
	;;
	3)
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		echo "$fichierB n'est pas conforme au journal, il a été modifié"
	fi
	;;
	4)
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		echo "$fichierA n'est pas conforme au journal, il a été modifié"
		
	fi
	;;
	4)
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		echo "$fichierA et $fichierB ne sont pas conforme au journal, ils ont été modifiés"
	fi
	;;
  esac
	done
done
#appel de la fonction pour gérer les conflits
lstcft
}

function Erep {
if [ -e "$ArbreA" ] && [ -d "$ArbreA" ] && [ -e "$ArbreB" ] && [ -d "$ArbreB" ]
then
	echo "Les Arbres A et B existent"
	prmain
else
	echo "Création des arbres A et B"
	mkdir $HOME/synchroniseur
	mkdir $HOME/synchroniseur/A
	mkdir $HOME/synchroniseur/B
	prmain
fi
}


#Création du journal de synchronisation
if [ -f "$journal" ] && [ -e "$journal" ]
then
	echo "journal déjà existant"
	Erep
else
	echo "Le journal n'existe pas, il va maintenant être crée"
	touch $HOME/synjournal.log
	Erep
	
fi






#Lien sources:
#https://stackoverflow.com/questions/5874090/how-to-get-diff-between-all-files-inside-2-folders-that-are-on-the-web
#https://stackoverflow.com/questions/180741/how-to-do-something-to-each-file-in-a-directory-with-a-batch-script
#https://askubuntu.com/questions/315335/bash-command-for-each-file-in-a-folder



#https://www.ionos.fr/digitalguide/serveur/configuration/commandes-linux/
#https://www.computerhope.com/unix/udiff.htm
#https://www.it-connect.fr/comparez-des-fichiers-entre-eux-avec-diff-sous-linux/
#https://www.funix.org/fr/unix/awk.htm
#http://www.shellunix.com/awk.html


