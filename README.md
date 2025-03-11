čau čau, přítel Ariny! :D

Nejdřív si pullněte do nějaký složky tenhle repositář: 
```git clone git@github.com:ArinaStrelt/herni-design.git```
Pak si nejlíp vytvořte branch na tu featuru co budete dělat: 
```git branch nazev_branche```
Pak se do ní přepněte: 
```git checkout nazev_branche```
A pak si vytvořte v godotu scénu, kde vytvoříte tu komponentu/featuru/mapu apod.
pomocí ```git add .``` přidáte všechny nový změny co jste udělali v současný složce, pak je třeba udělat ```git commit -m "tady napiště stručně co jste udělali"``` a pak dejte ```git push```.
Nakonec na webu pak vytvoříte novej merge vaší branche s masterem, vyřešíte případný konflikty a hlavně to pak v tom masteru otestujete.
Kdyžtak ChatGPT s tímhle umí poradit když si nebudete vědět rady.
Taky nezapomínejte si dát ```git pull``` ať máte aktuální stav.

Je to 100x lepší způsob než si mezi sebou posílat .zip soubory hra_final_FINAL apod. :D taky je tohle standardem v praxi.

Snažte se každou věc udělat funkční samostatně jako vlastní scény, který pak pospojujete dohromady. Godot funguje nejlíp pomocí kompozice a ne OOP, pro enemáky a player controller doporučuju si udělat state machine.
Taky se hodně budou hodit autoload skripty.

Kdyžtak můžete checknout mou godot hru [Scrap Reaper](https://github.com/Rionit/Pirate-Software-Game-Jam-16)

Taky doporučuju používat GDScript a ne C#, je na to víc návodů a dokumentace, navíc je dost podobnej Pythonu.

[Tohle](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html) doporučuju pro Blender, urychlí to váš export a import do Godotu. Nejlíp se pracuje s GLB formátem.

Good luck! :)
