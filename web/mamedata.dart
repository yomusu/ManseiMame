part of manseimame;

var ImageFileData = {
"bg": "./img/bg.png",
"bu01": "./img/bu01.png",
"bu02": "./img/bu02.png",
"bu03": "./img/bu03.png",
"hit": "./img/hit.png",
"mame": "./img/mame.png",
"mameicon": "./img/mameicon.png",
"oni_b01": "./img/oni_b01.png",
"oni_b02": "./img/oni_b02.png",
"oni_b03": "./img/oni_b03.png",
"oni_b04": "./img/oni_b04.png",
"oni_b05": "./img/oni_b05.png",
"oni_r01": "./img/oni_r01.png",
"oni_r02": "./img/oni_r02.png",
"oni_r03": "./img/oni_r03.png",
"oni_r04": "./img/oni_r04.png",
"oni_r05": "./img/oni_r05.png",
"resultbg": "./img/resultbg.png",
"start": "./img/start.png",
"starttext": "./img/starttext.png",
"title": "./img/title.png",
"gamebg": "./img/oldbg.png",
};


var SoundFileData = {
  "gameover" : "./sound/gameover.ogg",
  "miss" : "./sound/miss.ogg",
  "throw" : "./sound/throw.ogg",
};


/*********************************************
 * 
 * セリフデータ
 * 
 */
//まるではずれ！
List serif1 = [
 ["おにさんたち「ふぉっふぉっふぉっ！",
  "　　　　　　　わるいこは たべちゃうぞ！",
  "　　　　　　　おれたちをたいじするには",
  "　　　　　　　１００ねんはやいぞ！」"],
];
//片方当り、両方あたり、だけど両方９０点以下
List serif2 = [
 ["おにさんたち「あぶない あぶない",
  "　　　　　　　ちょっとは おなががかゆかったなかな？",
  "　　　　　　　れんしゅうしてでなおしな！ガオー」"],
];
//片方当り、両方あたり、だけど片方９０点以上
List serif3 = [
 ["おにさんたち「いてててててーーー！やられたーー！",
  "　　　　　　　けど まだひとりが げんきだから",
  "　　　　　　　あとはまかせたぞー」"],
 ["ぶーちゃん「あとすこしだったのに。",
  "　　　　　　こんどこそ やっつけるぞ！」"]
];
//両方９０点以上
List serif4 = [
 // ぶーちゃん、画面中央に立つ
 ["ぶーちゃん「やったぞ！これで おにさん をやっつけたぞ！」"],
 ["あかおにさん「いたい！いたいよー！",
  "　　　　　　　もう こないからゆるしてよ〜」"],
 ["ぶーちゃん「よおし！もう わるいことはしないんだよ。",
  "　　　　　　おにがしまにかえって はやくねなさい」"],
  // ぶーちゃん退場
  // その後、鬼が普通表示に画像切り替わる
 ["あかおにさん「はぁい！、、、、、ふふふっ",
  "　　　　　　　ぶーちゃんもあまいなぁ」"],
 ["あおおにさん「そうだな あかおにどん。",
  "　　　　　　　いまのうちに万かつサンドをたべて",
  "　　　　　　　ちからをつけて こんどこそまけないぞ！",
  "　　　　　　　もぐもぐ」"],
 ["あかおにさん「ちからがモリモリわいてきたぞ！",
  "　　　　　　　こんどこそまけないぞ！",
  "　　　　　　　よおし しょうぶだぁ」"],
 ["ぶーちゃん「あれっ！おにたちがげんきになっちゃった！」"],
];
// 2週目ダメ
List serif5 = [
 ["ぶーちゃん「うーん、まさかおにさんが　またげんきに",
  "　　　　　　なるとはおもわなかったなぁ」"],
 ["ぶーちゃん「万かつサンドをたべるとは　おにさんもかんがえたねぇ",
  "　　　　　　またチャレンジして　おにがしまに　おいかえすぞ！」"],
];
// 2週目倒した
List serif6 = [
  // ぶーちゃん、画面中央に立つ
 ["ぶーちゃん「やったぁ！　ついにおにさんをたいじしたぞ！",
  "　　　　　　これでへいわにくらせるね！」"],
 ["ぶーちゃん「おなかがへったから　もーちゃんをさそって",
  "　　　　　　にくのまんせいにしょくじに いってくるね！"],
 ["ぶーちゃん「バイバイ」"],
 // ぶーちゃん、退場
];

TextRender  tren = new TextRender()
..fontFamily = fontFamily
..fontSize = "28pt"
..textAlign = "center"
..textBaseline = "middle"
..fillColor = Color.Black
;

TextRender  scoreTren = new TextRender.from(tren)
..fontSize = "32px"
..textAlign = "right"
..textBaseline = "top"
;

TextRender  messageTren = new TextRender.from(tren)
..fontSize = "16px"
..textAlign = "left"
..textBaseline = "alphabetic"
..lineHeight = 25
;

