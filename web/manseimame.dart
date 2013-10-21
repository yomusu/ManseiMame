
library manseimame;

import 'dart:html';
import 'dart:async';

import 'geng.dart';
import 'vector.dart';

part 'mamedata.dart';
part 'manseimame2.dart';


void main() {
  
  Timer.run( () {
    
    // 画像読み込み
    geng.imageMap.addAll( ImageFileData );
    
    // サウンド読み込み
    geng.soundManager.addAll( SoundFileData );
    
    // ハイスコアデータ読み込み
    geng.hiscoreManager.init();
    
    // SoundのOn/Off
    bool sound = window.localStorage.containsKey("sound") ? window.localStorage["sound"]=="true" : false;
    geng.soundManager.soundOn = sound;
    
    // Canvas
    num scale = isMobileDevice() ? 0.5 : 1;
    geng.initField( width:480, height:480, scale:scale );
    
    query("#place").append( geng.canvas );
    
    // 開始
    geng.screen = new Title();
    geng.startTimer();
  });
}

/***********
 * 
 * タイトル画面の表示
 * 
 */
class Title extends GScreen {
  
  var _anime;
  
  void onStart() {
    geng.objlist.disposeAll();
    input = new InputHandler();
    
    //---------------------
    // StartGameボタン配置
    Sprite  sp0 = new Sprite.withImage("starttext");
    
    _anime = new AnimationRender.mugen()
    ..milliseconds = 500
    ..spriteList = [sp0,null]
    ..start();
    
    var sp = new Sprite.withRender( _anime.render, width:sp0.width, height:sp0.height )
    ..x = 300
    ..y = 380;
    
    // マウスボタンハンドラ
    input.onRelease = (e) {
      input.onRelease = null;
      geng.soundManager.play("throw");
      new Timer( const Duration(milliseconds:500), () {
        geng.screen = new GameScreen();
      });
    };
    
    //---------------------
    // 最前面描画処理
    onBackRender= ( GCanvas2D canvas ) {
      canvas.c.drawImage(geng.imageMap["title"], 0, 0);
      sp.render(canvas);
    };
    
    //---------------------
    // ゲームデータのクリア
    
    // ゲームの周回数クリア
    gameClearCount = 0;
    // スコアクリア
    score = 0;
  }
}

/** ゲームのスコア */
int score = 0;
/** まめの残り */
int remainsOfMame = 3;
/** ゲームのクリア数 */
int gameClearCount = 0;

/**
 * ゲーム画面
 */
class GameScreen extends GScreen {
  
  Boochan boo;
  
  void onStart() {
    geng.objlist.disposeAll();
    input = new InputHandler();
    
    // まめの数初期化
    remainsOfMame = 3;
    
    // 鬼表示
    var redOni = new Oni.red()
    ..tag = "redOni";
    geng.objlist.add( redOni );

    var blueOni = new Oni.blue()
    ..tag = "blueOni";
    geng.objlist.add( blueOni );

    // ぶーちゃん
    boo = new Boochan();
    geng.objlist.add( boo );
    
    //-------
    // まめと鬼の当たり判定
    var onis = [ redOni, blueOni ];
    var mameConf = (Mame mame) {
      for( Oni oni in onis ) {
        var onx = mame.getXOnY( oni.y );
        if( onx!=null ) {
          var s = oni.getScoreWithX( onx );
          if( s!=null ) {
            print( "hit s=$s onx=$onx" );
            oni.putHitMark( onx );
            mame.dispose();
            if( s==100 )
              oni.ouch();
            else
              oni.kayui();
            score += s;
          }
        }
      }
    };
    
    //-----
    // マウスハンドラ用透明なボタン→まめを投げる
    // startしてから有効となる
    var onPress = (e) {
      // クリックされた
      if( remainsOfMame > 0 ) {
        // まめ投げる
        geng.soundManager.play("throw");
        
        Mame  mame = new Mame()
        ..onForwarded = mameConf
        ..pos.set( boo.pos )
        ..speed.y = -5.0;
        
        geng.objlist.add( mame );
        
        // まめ減らす
        remainsOfMame--;
      }
    };
    
    //--------
    // Start表示
    var start = new StartCounter()
    ..callback = () {
      // ぶーちゃんの動作開始
      boo.start();
      // 2週目だったら鬼の動きを設定
      if( gameClearCount==1 ) {
        redOni.speed.x = 1.0;
        blueOni.speed.x = 1.0;
      }
      // 入力受付
      input.onPress = onPress;
    };
    geng.objlist.add(start);
    start.start();
    
    //---------------------
    // 結果表示
    boo.onOutOfScreen = () {
      boo.dispose();
      // マウスハンドラ削除
      input.onPress = null;
      // 結果判定
      var next;
      if( gameClearCount==0 ) {
        // 1週目
        if( redOni.hasBeenDamaged || blueOni.hasBeenDamaged ) {
          if( redOni.isOuch && blueOni.isOuch ) {
            // 2匹とも真ん中
            next = new MessageScreen2(serif4);
          } else if( redOni.isOuch || blueOni.isOuch ) {
            // どっちか真ん中
            next = new MessageScreen(serif3);
          } else {
            // どっちも真ん中でない
            next = new MessageScreen(serif2);
          }
        } else {
          // 全然ハズレ
          next = new MessageScreen(serif1);
          geng.soundManager.play("miss");
        }
      } else {
        // 2週目
        if( redOni.isOuch && blueOni.isOuch ) {
          // 2匹とも真ん中
          next = new MessageScreen3(serif6);
        } else {
          // 2匹とも真ん中
          next = new MessageScreen(serif5);
        }
      }
      
      geng.screen = next;
    };
    
    //---------------------
    // 最背面表示
    onBackRender= drawGameBackground;
  }
  
}

void drawGameBackground( GCanvas2D canvas ) {
  canvas.c.drawImage(geng.imageMap["gamebg"], 0, 0);
  
  // 豆表示
  var mame = geng.imageMap["mameicon"];
  var x = 340;
  for( int i=0; i<remainsOfMame; i++ ) {
    canvas.c.drawImage(mame, x, 400);
    x += 40;
  }
  // 得点表示
  canvas.drawTexts(scoreTren, ["$score"], 140, 400);
}

/**
 * ぶーちゃん
 */
class Boochan extends GObj {
  
  var onOutOfScreen;
  
  Sprite sp;
  Sprite spThrow;
  int width=83;
  
  Vector  pos = new Vector();
  Vector  speed = new Vector();
  var _anime;
  
  void onInit() {
    var sp01 = new Sprite.withImage("bu01")
    ..offset = new Point(83~/2,105~/2);
    var sp02 = new Sprite.withImage("bu02")
    ..offset = new Point(83~/2,105~/2);
    spThrow = new Sprite.withImage("bu03");
    
    pos.x = -width.toDouble();
    pos.y = 320.0;
    
    _anime = new AnimationRender.mugen()
    ..milliseconds = 500
    ..spriteList = [sp01,sp02];
    
    sp = new Sprite.withRender( _anime.render, width:83, height:105 );
  }
  
  void start() {
    _anime.start();
    speed.x = 2.0;
  }
  
  void onProcess( GPInfo handle ) {
    // 座標をすすめる
    pos.add( speed );
    // 画面外判定
    if( pos.x >= (480+width) ) {
      dispose();
      // ゲーム直後メッセージ表示に遷移
      if(onOutOfScreen!=null )
        onOutOfScreen();
    }
    // スプライトに座標転写
    sp.x = pos.x;
    sp.y = pos.y;
    
    geng.repaint();
  }
  void onPrepareRender( RenderList renderList ) {
    renderList.add( 100, sp.render );
  }
  
  void onDispose() {
    _anime.stop();
  }
}

/**
 * まめ
 */
class Mame extends GObj {

  Sprite  _sp;
  final Vector  oldpos = new Vector();
  final Vector  pos = new Vector();
  final Vector  speed = new Vector();
  
  var onForwarded;
  
  void onInit() {
    _sp = new Sprite.withImage("mame")
    ..offset = new Point(14,5);
  }
  
  void onProcess(GPInfo handle){
    // まめをすすめる
    oldpos.set(pos);
    pos.add(speed);
    // 画面外判定
    if( pos.y < -_sp.height )
      dispose();
    // 鬼に当たり判定
    if( onForwarded!=null )
      onForwarded(this);
    
    _sp.x = pos.x;
    _sp.y = pos.y;
    
    geng.repaint();
  }
  
  void onPrepareRender( RenderList renderList ) {
    renderList.add( 100, _sp.render );
  }
  
  num getXOnY( targety ) {
    var to = this.pos;
    if( oldpos.y < targety )
      return null;
    if( to.y > targety )
      return null;
    
    var dy1 = oldpos.y - targety;
    var dy2 = oldpos.y - to.y;
    
    var dx2 = to.x - oldpos.x;
    
    var dx1 = (dy1 / dy2) * dx2;
    
    return (oldpos.x + dx1);
  }
  
  void onDispose() {
  }
}


/*
 * 鬼
 */
class Oni extends GObj {
  
  bool isKayui;
  bool isOuch;

  Vector  speed = new Vector();
  Vector  move = new Vector();
  Vector  dpos = new Vector();
  
  Sprite  sp;
  Sprite  sp1,sp2,sp3,sp4,sp5;
  Sprite  hitSp;
  var anime;
  final List<num>  hitPoints = new List();
  
  /** ダメージを受けたかどうか */
  bool get hasBeenDamaged => isKayui || isOuch;
  
  num get x => dpos.x + move.x;
  num get y => dpos.y + move.y;
  
  
  Oni.red() {
    sp1 = new Sprite.withImage("oni_r01")
    ..offset = new Point( 124, 146 );
    sp2 = new Sprite.withImage("oni_r02")
    ..offset = new Point( 125, 144 );
    sp3 = new Sprite.withImage("oni_r03")
    ..offset = new Point( 125, 150 );
    sp4 = new Sprite.withImage("oni_r04")
    ..offset = new Point( 120, 155 );
    sp5 = new Sprite.withImage("oni_r05")
    ..offset = new Point( 132, 159 );
    // 初期の位置
    dpos..x = 140.0 ..y = 156.0;
  }
  
  Oni.blue() {
    sp1 = new Sprite.withImage("oni_b01")
    ..offset = new Point( 109, 145 );
    sp2 = new Sprite.withImage("oni_b02")
    ..offset = new Point( 109, 156 );
    sp3 = new Sprite.withImage("oni_b03")
    ..offset = new Point( 109, 159 );
    sp4 = new Sprite.withImage("oni_b04")
    ..offset = new Point( 114, 145 );
    sp5 = new Sprite.withImage("oni_b05")
    ..offset = new Point( 126, 149 );
    // 初期の位置
    dpos..x=340.0 ..y = 156.0;
  }
  
  void onInit() {
    sp = new Sprite.withRender((c) => sp1.render(c), width:150, height:150 );
    hitSp = new Sprite.withImage("hit")
    ..offsetx = 13
    ..offsety = 10;
    // ouchフラグのリセット
    isOuch = false;
    isKayui = false;
    // ヒット表示のクリア
    hitPoints.clear();
  }
  
  void onProcess( GPInfo handle ) {
    
    move.add( speed );
    if( move.x.abs() > 32 )
      speed.mul( -1.0 );
    
    sp.x = x;
    sp.y = y;
    
    if( speed.scalar().abs() > 0 )
      geng.repaint();
  }
  
  void onPrepareRender( RenderList renderList ) {
    renderList.add(10, (c){
      sp.render(c);
      // ヒットマークを描画
      for( var p in hitPoints ) {
        hitSp.x = p+x;
        hitSp.y = y;
        hitSp.render(c);
      }
    });
  }
  
  int getScoreWithX( num px ) {
    var rd = px - x;
    var d = rd.abs();
    if( d < 5 ) {
      return 100;
    } else if( d < 12 ) {
      return 60;
    } else if( d < 20 ) {
      return 30;
    } else if( d < 46 ) {
      return 10;
    }
    return null;
  }
  
  void putHitMark( num px ) {
    var dx = px - x;
    hitPoints.add( dx );
  }
  
  void fukkatsu() {
    if( anime!=null ) {
      anime.stop();
      anime=null;
    }
    onInit();
  }
  
  /** あたり */
  void ouch() {
    if( anime==null ) {
      anime = new AnimationRender.mugen()
      ..milliseconds = 400
      ..spriteList = [ sp2, sp3 ]
      ..start();
      sp.sprenderer = anime.render;
      isOuch = true;
      speed.x = 0.0;
    }
  }
  /** かゆい */
  void kayui() {
    if( anime==null ) {
      anime = new AnimationRender.mugen()
      ..milliseconds = 400
      ..spriteList = [ sp4, sp5 ]
      ..start();
      sp.sprenderer = anime.render;
      isKayui = true;
      speed.x = 0.0;
    }
  }
  
  void onDispose() {
    if( anime!=null )
      anime.stop();
  }
}

/**
 * スタート時の表示
 */
class StartCounter extends GObj {
  
  Sprite sp;
  var _loop;
  var callback;
  
  void onInit() {
    
    Sprite  img = new Sprite.withImage("start");
    img.offsetx = img.width ~/ 2;
    img.offsety = img.height ~/ 2;
    
    _loop = new AnimationRender.loop( 3, (){
      callback();
      // 自身の廃棄処理
      dispose();
    })
    ..milliseconds = 500;
    _loop.add( img );
    _loop.add( null );
    
    sp = new Sprite.withRender(_loop.render, width:img.width , height:img.height )
    ..x = 480 ~/ 2
    ..y = 260;
  }
  
  void onProcess(GPInfo handle){}
  
  void onPrepareRender( RenderList renderList ) {
    renderList.add(1000, sp.render );
  }
  void onDispose() {
    _loop.stop();
  }
  
  void start() {
    _loop.start();
  }
}

