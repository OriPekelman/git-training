# Titre du cours

## Partie 1
### Chapitre 1.1
#### Titre 1.1.1
##### Sous-titre 1.1.1.1
###### Sous-sous-titre 1.1.1.1.1

## La syntaxe de base

Suivez la syntax de base de Markdown : [Plus d'info sur Markdown version Github](https://guides.github.com/features/mastering-markdown/)


J'écris du texte normal...

Je change de paragraphe en sautant une ligne.
Si je ne fait que revenir à la ligne, le texte ne revient pas à la ligne dans le cours.  
Si je veux revenir à la ligne, j'ajoute deux espaces en fin de ligne précédente.

Liste à puce :
-   item 1
-   item 2
    -   item 2.1
    -   item 2.2
-   item 3

Liste numérotée (je ne suis pas obligé d'incrémenter le numéro):
1.  item 1
1.  item 2
    1.   item 2.1
    1.   item 2.2
1.  item 3


## La syntaxe spécifique

### Les blocs de mise en avant

#### Citation

> Ceci est une citation
> que j'écris sur plusieurs lignes.
> 
> Je commence ici un nouveau paragraphe
> > Et là une sous-citation
>
> Et me revoilà dans la citation principale

> Si je fais ça, ça ne commence pas un nouveau bloc !

<!-- -->
> Il faut ajouter soit du texte soit un commentaire (`<!-- -->`) entre les deux

:warning: Attention : bien séparer le bloc des autres paragraphes par, *au moins*, un saut à la ligne avant et après.

#### Bloc d'information

> **:information_source:** Ceci est un bloc d'info
> que j'écris sur plusieurs lignes.
> Il sera converti en une balise info (bleue).
> 
> Je commence ici un nouveau paragraphe  
> Je commence ici une nouvelle ligne
>
> > Je peux faire une citation dedans
>
> Je peux mettre du text en **gras** ou _italic_,
> -   des listes
> -   à puces...



#### Bloc Attention

> **:warning:** Ceci appelle l'attention et sera converti en balise warning (orange)
> 
> ... et les même règles qu'avec le bloc _information_ s'appliquent.

#### Bloc Danger

> **:x:** Ceci est un danger et sera converti en balise danger (rouge)
> 
> ... et les même règles qu'avec le bloc _information_ s'appliquent.

#### Bloc Question

> **:grey_question:** Ceci est une question qui sera transformée en balise question
> 
> ... et les même règles qu'avec le bloc _information_ s'appliquent.

ou

> **:question:** Ceci est une question qui sera transformée en balise question (_la couleur sera la même qu'avec la version ci-dessus_)
> 
> ... et les même règles qu'avec le bloc _information_ s'appliquent.



### Code
On attaque le code...

#### Code inline
Voici un exemple de `Code inline`, mais la phrase n'est pas finie !

#### Bloc de code
Les exemples ci-dessous vont créer des blocs de code

```
Salut tout le monde !
```

```python
print("hello Régis le pythonien !")
```

```java
public class Main {
    public static void main(String[] args) {
        System.out.println("Salut Loïc le javanais !");
        System.out.println("Fichtre ! Le Java c'est verbeux !");
    }
}
```

```ruby
puts "Salut Céline la rubyiste !"
```

```shell
echo "Salut Nico le sysadmin !"
```

Pour les autres syntaxes de code, voir _Ace_ : <https://github.com/ajaxorg/ace/tree/master/lib/ace/mode>


#### Console
Et pour afficher une sortie console :

```console
Salut tout le monde !
Voici la ligne 2
```

### Raccourcis clavier

Voici LE raccourcis clavier qui va bien :  <kbd>Ctrl</kbd>+<kbd>S</kbd> !

Oui bon, la ramenez pas avec votre <kbd>pomme</kbd>/<kbd>cmd</kbd> ché pô kwa !


### Tableaux

| First Header                | Second Header                |
|-----------------------------|------------------------------|
| Content from cell 1         | Content from cell 2          |
| Content in the first column | Content in the second column |


### Emote icons
-   :magicien:
-   :diable:
-   :ange:
-   :ninja:
-   :pirate:
-   :zorro:
-   :honte:
-   :soleil:
-   :waw:
-   :lol:
-   :euh:
-   :colere:
-   `>_<`
-   :p
-   :)
-   :D
-   ;)
-   :')
-   :(
-   :o
-   o_O
-   ^^
-   :-°


### Images

**TODO**

> :x: La gestion des images est expérimentale.
> Elle ne fonctionne bien que pour le preview, mais pas à l'import


Pour les images simples :

![Texte alteratif](chemin/vers/image)

> :warning:
> Les images en "inline" dans le texte posent soucis avec CLAIRE :
> -   ne pas mettre plusieurs images inline dans le même paragraphe (balise `&lt;p&gt;`)
> -   dans les listes à puces, les images ne fonctionnent que si elle sont dans un paragraphe (balise `&lt;p&gt;`)


Pour ajouter des images avec une légende :

![Texte alternatif](chemin/vers/image "Légende de l'image")


> :warning:
> Les images ne sont pas gérées ni uploadées automatiquement,
> il vous faudra les traiter une par une à la main après avoir importé le cours
> cf ./README.md


#### Image avec légende

![Texte alternatif si image non trouvée](img/image1.png "Le titre/légende de l'image")


### Formules

**TODO**

> :x: Les formules LaTeX ne sont pas encore implémentées



### Commentaires

`<!--- Ceci est un exemple de commentaire en markdown. --->`

Note : dans cet exemple il est quand même affiché car il est dans une balise `<code>`.

<!--- Le vrai commentaire qui ne sera pas évalué est ici ;-) --->
