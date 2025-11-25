- je ne pouvais pas faire npx prisma db pull car le backend n'arriver pas a ce connecter a la db pour resoudre ceci j'ai modifier dans docker compose la ligne qui ouvre les ports de : 8080:5432 --> 5432:5432
- prisma genere un fichier 
- J'ai ajouter un volume partager dans le backend car j'ai besoin de recuperer les parametre de prisma.
- demander a chatgpt si je dois faire npx prisma generate dans le container ou bien en local 
- npx prisma generate doit etre fait dans le container et a chaque fois que je build mon projet. prisma generate transforme mon schema.prisma en JS utilisable dans le backend. 
cette commande doit etre executer a chaque changement du schema et chaque build Docker.
