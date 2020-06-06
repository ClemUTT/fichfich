#!/bin/bash
#Le script doit être situé dans le répertoire root de l'utilisateur pour l'instant
#variables
journal="synjournal.txt"
ArbreA="/root/synchroniseur/A"
ArbreB="/root/synchroniseur/B"

#Status de la synchronisation
Esync="false";

#fonction du synchronisation sur le journal
function Jsync {
if [ $Esync = true ]
then
	#affichage de la date de synchronisation
	date
	#affichage du chemin obsolu du fichier dans le journal
	find ./ -name $fichier >> $journal
	#affichage des droits, nom, date, propriétaire, groupe, le type et taille du fichier
	ls -l >> $journal
else
	echo "La synchronisation pour le fichier $fichier à échouée"
fi
	
}

#fonction du synchroniseur
function prmain {
#Utilisation d'un case pour tester les différentes possibilités sur les répertoires / copier les fichiers entre le 2 répertoires

for fichierA in $ArbreA/*
do
  echo "Affichage du contenu des fichiers de l'arbre A"
  cat $fichierA
  for fichierB in $ArbreB/*
	do
	echo "Affichage du contenu des fichiers de l'arbre B"
	cat $fichierB

  case $fichierA in
	0);;
	1);;
	2);;
	*)
	Condition par défaut
	;;
  esac
	done
done
}

function Erep {
if [ -e "$ArbreA" ] && [ -d "$ArbreA" ] && [ -e "$ArbreB" ] && [ -d "$ArbreB" ]
then
	echo "Les Arbres A et B existent"
	prmain
else
	echo "Création des arbres A et B"
	mkdir ./synchroniseur
	mkdir ./synchroniseur/A
	mkdir ./synchroniseur/B
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
	touch synjournal.txt
	Erep
	
fi






#Lien sources:
#https://stackoverflow.com/questions/5874090/how-to-get-diff-between-all-files-inside-2-folders-that-are-on-the-web
#https://stackoverflow.com/questions/180741/how-to-do-something-to-each-file-in-a-directory-with-a-batch-script
#https://askubuntu.com/questions/315335/bash-command-for-each-file-in-a-folder

