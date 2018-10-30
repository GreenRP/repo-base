local _, U1 = ...;
U1Donators = {}
local topNames = "奶瓶小裤衩-血色十字军,叶心安-远古海滩,释言丶-伊森利恩,魔道刺靑-菲拉斯,乱灬乱-伊森利恩,瓜瓜哒-白银之手,Monarch-霜之哀伤,海潮之声-白银之手,败家少爷-死亡之翼,不含防腐剂-诺森德,不要捣乱-斯克提斯,大江江米库-雷霆之王,幽幽花舞-贫瘠之地,蒋公子-死亡之翼,御箭乘风-贫瘠之地,Majere-冰风岗,邪恶肥嘟嘟-卡德罗斯,空灵道-回音山,橙阿鬼丶-达尔坎,贞姬-霜之哀伤,剑四-幽暗沼泽,站如松-夏维安";
local recentDonators = {["桑德兰"] = "E0,该隐与亚伯",["末日行者"] = "E0,少男裴;Ex,青丶檸;Ew,啟蟄,Zanxus,蜜思丶丹,旋风少女哒哒,菲菲向前冲;Eu,卪顺子卪,红楼丶小小;Es,北月凝霜;Er,钢铁丶苍穹,铁丶心,熊猫滚球球;Eq,放牛叔叔;Ep,沉醉天翼,落花流氺丶;En,於心有愧,仰望虚空;Em,逸见艾丽卡,雪落叔叔,烟雨潇凝,古登陶克;El,水很大;Ek,丶丶伊立蛋丶,小不忍;Ej,捌捌肆捌,花落愺愺;Ei,佩丨奇,织雾丨糖糖,仙仙灬;Eh,票房的毒藥",["凤凰之神"] = "E0,心中桐城,约瑟芬儿;Ey,其实丶稻花香,Evangalian,森森喔;Ex,快开灯,闲看花开,圣西罗的梦;Ew,丿柒丶雪灬,森归遇白鹿,大榴莲丷;Ev,弑神灬鬼;Eu,莫高雷扫地牛,老鸡嗨小荫,淡忘的荣耀丶;Et,阿浩啊;Es,嗦嗨,丨拉菲丶,染清溪,陌颜依醉,踏疯,欧皇风景;Er,霸气灬死射;Eq,指间流沙丶,化身孤岛的鯨;Ep,花菜丶;Eo,天涯之远;En,看你鬽;Em,狂流哈喇子丶,茹释喵,、小暴,喷火的神灵;El,宮商角徵羽;Ek,灬大火法灬;Ej,耿秋;Ei,丶五月雨,长庚在东,燃烧的灵魂,枣真夜,可爱术,寂寞繁华;Eh,清风无常,蟑螂丶恶霸,小爅",["无尽之海"] = "E0,冷月萧然;Ey,手语,罗罗诺亚丶圆;Ex,记得穿实验服;Ew,烟雨亦成诗;Ev,耗蓝,电器;Er,凶手不止一个;Eq,暴躁的二公子;Eo,小鱼干不见了;Em,冲锋裂地斩;Ek,無敵神棍德,恶魔也疯狂丶;Ei,夜幕下的侵袭,凌衷遗言,吧啦吧啦咘;Eh,咸鱼咆哮",["羽月"] = "E0,超级元元;Ev,超级蛋蛋;Es,逗你玩的小舞;Eq,壹玖玖叁夭夭",["塞拉摩"] = "E0,Lovexue;Ey,真的眼瞎;Ex,猛削瘸子好腿;Eu,世界和平丶;Es,和尚玩游戏呼;Em,Mine;El,豆豆丶奥特曼;Ej,冲锋崴了脚丶",["冰风岗"] = "E0,曠野瘋;Ez,梦之猫妖;Ex,丶贞德丶;Ev,伍德沃特;Ep,昌北纯爷们;En,噗嗨哈;Em,清清豌豆,萨利休斯;Ek,有点小鸡冻;Ei,水信灬玄饼;Eh,甜水,你英俊的阿爸",["奥特兰克"] = "E0,羅尛黒;Ew,兰博坚尼;Eu,哈尼十四;Er,奔雷手丶文泰;En,破裤;Em,害羞的菊花,洪镇乐翁;Ek,之只止御用奶;Ej,浪息亚麻布;Ei,眼线高手,老水手小甜菜,夜与胡渣",["卡拉赞"] = "E0,九九大哥法师,九九小哥;En,暴躁老哥,茜雨寳贝,糖棉花",["阿古斯"] = "E0,茉小丝;Ey,鱼鳕交加,幺丶妹儿,很纯灬很暧昧;Ex,清风丶;Es,乖乖肉丶尕;Er,费因斯;Ep,哎哟丶吊爆了;Eo,阿伊索;Em,熊仔熊;El,红颜灬伊然;Eh,逆丶夏",["罗宁"] = "E0,曲港跳鱼;Ez,飞翔的大熊猫;Ew,哆来咪法,小宫惠那;Ev,猪头洋,火之愉快;Eu,穆垃丁桐须,玩家锦鲤;Et,千凝;Er,戒丶射,隐雪的法侍;Eq,冫钅丶;Ep,无敌拉拉;Eo,Hots;En,还是小木桩;Em,莫丶库什勒,圣光修女,优秀的吉米;Ek,尛鋺餖,夜风轻语;Ej,不如一见;Ei,安薇娜丶语歌;Eh,风灵之语",["熊猫酒仙"] = "E0,Mangol,丶祷,丶佑,丶寻;Ez,小煩姑娘,大鲸鱼啊;Ex,晨风书白,舒麻子;Ew,零叁零叁;Er,缘音;Ep,舞袖轻盈;Eo,巭丶大师;Em,荆楚九頭鳥;El,天狼星下;Ek,月下独饮酒;Ej,火龙奇士;Ei,Âô;Eh,风起肃然,名字不能乱写",["死亡之翼"] = "E0,红豆包,來生缘,张大冰;Ez,夶妖怪縋莪吖,冻柠乐丿,箭追魂;Ex,Jacktang;Ew,少女之友,Emmnm;Ev,魂寂丶,祭音,妮特丽公主;Eu,常威又打来福,风暴蛮牛,在下丿霍元乙,冫二胖啊;Et,栀晚;Es,大熊顿顿,嫣然;Er,熊猫怎么了,张欧皇丶;Eq,牛肉香菇辣酱,冬風;Eo,丷小淘气,厄姆利索,影翳的阿昆达;En,八级大地震,壹切唯我造;Em,顽咖,咯咯无;El,一只绝味鸭;Ek,你也在等我吧;Ej,丨远坂凛丨,巧克力花和尚;Ei,重生知会;Eh,斷腸,胖嘟小佳宝,Raptorx",["影之哀伤"] = "E0,半夜拉稀;Ez,小杰丶丶,枕边小茉莉,忘我大德;Ex,战爭领主;Ew,Kathie;Eu,渡弦丶暴走咕;Et,水深火热;Er,千与;Eq,老板快来玩啊;Ep,柠初丶,干戈余烬,海琴烟;Eo,猎手丶小青春,黑风喜牛牛;En,杨柳依雨雪霏;Ek,豌豆猎手,邦桑迪;Ej,猩红之瓶,香橙与咖啡;Ei,Ewxyzz",["阿斯塔洛"] = "E0,虚无空痕;Er,阿瑞斯之怒;En,黎明挽歌",["主宰之剑"] = "E0,李少;Ez,美味小流年,涂山白月初;Ex,灭団小能手,神秘的箱子;Ev,能行,尊贵的阿昆达;Eu,泰图髯;Et,羊肉垫卷子丶,Tevis,简奥斯汀;Er,静落晓萱,凉暮;Eq,北府乄小正太,画未难成,窗前白月光;Ep,崂山道士,八歧邪神,冰冷风歌,千古;Eo,你的小鱼干,一起看皇篇;En,吴清语,乖一点就亲你,非常皮;Em,半丨藏,君不劍;El,帅气的二狗子;Ek,丨卫庄丨;Ej,夕阳红斗士,怕屁,怕芼,一心为你灬;Ei,滚地三连,吴起展;Eh,黎明之锤丶",["恶魔之魂"] = "E0,柚莉嘉;En,融融月;El,大战吊",["达纳斯"] = "E0,凉薄;Ex,悠悠小舞",["贫瘠之地"] = "E0,丿丹青厌,灬肥皂菌;Ez,林荫下的萌萌,希腊宝宝;Ex,幻桜;Ew,奇犽揍敌客丶,胸大丶声甜;Eu,就想睡一会,一毛;Et,王熊熊,肆意灬泯灭;Es,若若小猎;Ep,欧洲的小西几,熊丶熊;En,老牛会变身,达大达大达,皮皮猎手心灬,就想骚一把,离樱错梦丶;Em,祭月隐修;El,再封试试丶;Ek,丶炉石,雷玛风行者,断丷角;Ej,月见海,待到重阳节;Ei,林妤丶,花魚兒;Eh,逝去的小法,冷血不语,雅皮",["格瑞姆巴托"] = "E0,笨牛;Ez,诺丁山的梦,丶嘚馒头;Ey,鹧咕哨,天无羡丶魁星;Ex,霜寒的火球;Ew,忽看花渐稀;Ev,阿森,可爱又爱笑;Eu,清风灬郎,咖啡馆电视剧;Et,青袖,噤區;Es,沐雨随风,炮卐神,大哥懒得说;Er,海然海然,丶浩克灬,将寂寞填满;Eq,杨加鲁鲁加,死戰不退;Ep,一个源氏;Eo,炸卷圈,笑熬浆糊,灵气之魂;En,夏亚专用丰田,那个喵丶,老狐;Em,浅术低吟,暗月小星星,静脉颤音;El,Tebieniubi,再读一个炎爆,张施主,夢裡輪迴;Ek,首席非酋,独行彡瘋,丷木乄槿丷;Ej,婆罗浮屠,晴空未眠,广寒清晖;Ei,丶拟墨画扇;Eh,一叶秋风",["加基森"] = "E0,萨布拉;Es,加拉哈德;Eo,呆呆魚;Em,Cczone",["石爪峰"] = "E0,魂觞;Ez,我心永橙;Ey,沫小淼,Pure;Ew,郁闷的达达;Eu,哈里马哈里欧;Ep,阿拉贡丨罗兰;Ei,丶电火流萤",["洛丹伦"] = "E0,希訁菲雨;Et,梦中捉糖丶;Es,月下花醉舞;Er,Ishooter;El,巴哈姆特践踏",["白银之手"] = "E0,玩玩喵喵,灬一咕;Ez,嘟粑粑;Ex,俄洛伊丶怒刃,Motorbubble;Ew,Octoberfirst,香烤小土豆,进击的盲人;Ev,水水清幽,许卿白头,用妹妹包围你,茶浓亦醉人;Eu,壹粒蛋的忧伤,强獵,沐雨弛雷;Es,北辰风行者;Er,胖胖哒熊猫;Eq,嘴巴咕咕,寂寞坏女人,辣子鸡翅,Overen;Ep,晚夕丶,风中飞舞的屁;Eo,寂树;En,三围真火,归隐风中,洪、七,光的颜色;Em,小文的骑士,時年丶初訫,雷凡乐,丶小意外灬,珊寶寶胸超大,这个名字最刁;El,阿福洛达特,小萌想,克灬宽,空气蕉灼;Ek,夏夜追凉,浮生闲云,棠小唐,郑天阳,宁折不弯;Ej,心口鼻息,追雪之风,田依城,跳刀空大,阿佛洛黛特;Ei,黑羊之墙,夷陵丶魏无羡,绝世面包;Eh,水歌调头,黎筱雨",["国王之谷"] = "E0,爱德莱德;Ez,卡斯巴尔,小西几,兰娜瑟尔血泪;Ex,大姐头维内托;Ew,雨落雨听雨;Eu,木箱;Er,世界需要奶字,阿墙;Eq,东门斩兔;Ep,祢菲儿;El,卡德伽马;Ej,乄米客;Ei,崩崩跳跳,宏灬宝灬莱",["伊森利恩"] = "E0,九洲问题少女;Ex,石三郎丶;Ew,Saberlilys,丨大尐姐丨;Ev,嗳呦丶欣;Et,宋哈娜丶;Es,释言丶,咕儿;Er,逝愿,阿皓、,散步的牛肉丸,Heavyback;Eq,打不赢我跑,泷谷源治,肥肉;Ep,聆丿聽,微笑的蒋美美;Eo,古乙丁三雨,Keyii;En,Letme,丶北落灬星辰;Em,大門,一莉亞德琳一;El,風無聖,咕咕是一只鸟;Ek,橘猫杀手,奶茶奶茶君,夜沐沉香,轻奏离殇,丿魑魅灬魍魉;Ej,皮皮闪电灬,邦嗓迪,春晖是最强哒;Ei,寂寞的法神,白沙翊",["黑铁"] = "E0,请你吃益达;Ew,救赎个锤子;Er,Berryman;Eq,吃生蚝啊;Em,一个小可爱;El,张无喵丶;Ek,Lostlife;Ej,Limerance;Eh,朴昭妍",["加兹鲁维"] = "E0,小喵的喵喵,我刚结束,口苗口苗,魅影郎邪;Ey,舞夜青螟风孀;Eu,Sammael;En,计生寺住持",["黑龙军团"] = "E0,青面阎罗;Ez,月影丶战狼;Er,淡淡嘚忧伤;Em,梦溪一囧架架;Ek,哎呀呆呆,Bwonsamdl;Ej,肝疼的阿昆达;Ei,黑了个手",["血色十字军"] = "E0,轩尼诗泡龙鞭;Ey,邵雲;Et,月明枫清;Es,你是阿宝吧;Er,扬州奶多哦,飞妖儿;Eq,丶不朽;Ep,天山老盗;En,清風丶,买了佛冷;Em,章兮兮;Ej,马猴烧酒猫爪,丶杏加橙,花为雨落,何时雨会停;Ei,复苏之风丿",["雷斧堡垒"] = "E0,三千流火;Ey,小女娲娘;Es,九曲寒波;Er,水冰月野兔;Eq,橙四不足;Em,Lapis",["泰拉尔"] = "E0,魔丶夜风",["巨龙之吼"] = "E0,Targaryen;Ez,宁知知;Ev,舞蹈演员花落;Em,俺们村丶奶奶",["月光林地"] = "E0,一生之水",["布鲁塔卢斯"] = "E0,斐波那契丶",["布兰卡德"] = "Ez,Madrosee;Eu,請你要開心,娇妹儿;Er,妞妞丷助理;Eq,Aclown;Ep,遥愿;Eo,这世界丶不懂,萌萌的尐熊猫;En,牛气冲云霄;Eh,为我撩人",["迅捷微风"] = "Ez,圣光丨忽悠;Ey,团长是单身汪;Eo,灵异学家,尘风丶;En,杨超跃;Ek,好甜灬;Ei,工程学博士,暖乄風;Eh,瘸腿的阿昆达",["索拉丁"] = "Ez,降临之子",["血环"] = "Ez,嫣然筱姐姐;Es,无言的诠释;Ep,橘小小先生;Em,致命遂志泽坎;Eh,墨丶小乖",["艾露恩"] = "Ez,雪妃爱做梦;Ey,伊利丹丶怒风;Er,雪舞灬傾城;Eh,小明",["金色平原"] = "Ez,守一;Ey,小东东爸;Ew,石坂栗;Eu,丿法爷丨,夜行者影歌;Ep,罗德尼格兰杰;Eo,大蔵里想奈;En,薇薇安丶柯文;El,天之刹那,紫宮初雪;Ek,李老鸨;Eh,小岩井四叶",["克尔苏加德"] = "Ez,輪回褻瀆;Ex,重剣無鋒;Er,一奅泯恩仇,逗戰聖佛;Eo,邪惡的早餐;El,影月酱;Ek,流火丶,卡迪福兰姆;Ei,仲村由理;Eh,千本菊,觸碰那记憶",["翡翠梦境"] = "Ez,鑫丶低调;Eo,Wéstlòvé;Ek,天雨正泽;Ej,蛮锤海明威;Ei,叫地主,影歌丷;Eh,糖门丨红手",["瑞文戴尔"] = "Ez,得来尼;Er,吃栆药丸",["希尔瓦娜斯"] = "Ez,急耳;Er,方大毛",["泰兰德"] = "Ez,末法;Ex,很伤很开心;Ew,哈登是大胡子;Es,人多不起名字",["迦拉克隆"] = "Ez,麦克美爹;Ew,俞文;Et,灵均正则;Er,浩荡;Eq,天边;En,馨语嫣然;El,桃杀;Ek,桥头恶霸,桐桐一桐;Ei,咔佧罗特",["埃德萨拉"] = "Ez,陈丶袋鼠;Ex,殇灬楚;Ew,未名斩;Er,康納麦格雷戈;Eo,游泳的生鱼片;El,安拉胡阿克巴;Ek,Surrebder;Ei,盗嗳",["暗影之月"] = "Ez,苏倾妍,社会我姗姐,君凌慕,糖小琪;Ey,火儛丶;Ev,王中王,森雪忆如痕;Eu,黑色暧昧;Ej,奥娜,月色了无痕",["库德兰"] = "Ez,基霸黑",["凯恩血蹄"] = "Ez,丶爆爆;Ey,一个狠人;Ew,未来多远;Ei,最后的赞歌丶",["闪电之刃"] = "Ez,幻化由心",["迦罗娜"] = "Ez,战地将军",["拉文凯斯"] = "Ey,一只海龟成功;Em,嘣次哒次;El,凛风冲击;Ek,爱莉丶斯菲尔",["燃烧之刃"] = "Ey,兮罗,细雨青禅,池冷羽;Ex,老胖贼;Eu,剑胆,疲倦的风丶,无无味,殇、南城;Et,黛瓦白墙;Er,田一夫;Eq,莫玥熙风,Silasx;Eo,恰一颗烟;Em,不熬夜的傀儡;Ej,大脚大牙怪,乱试佳人,苏坡密;Ei,大哉乾乾,Shevchenk;Eh,你敢打熊猫丶,奶残",["轻风之语"] = "Ey,孤灬星;Et,碧菡;El,鮮衣怒馬",["试炼之环"] = "Ey,Âãäåâãmmäåâã;Ep,肉团团,暗夜灬流星;Ek,王者迪克;Ej,牛德华;Ei,Augusto",["丽丽（四川）"] = "Ey,完美杜蕾斯;Ew,闲云随鹤;Ev,晓桀;Er,鬼乄泣,水深火熱;Eq,大白白小班,Stormshinobi,凯恩黑刃;Ep,岷山情结,猎心一万年;En,;Em,扶地魔,丨智妍丨;Ei,被阉掉的布偶,逆境天堂;Eh,西樓",["海克泰尔"] = "Ey,心里有点逼数,悟空大老爷,一起蛤脾;Eu,請叫我紅領巾,温岭幼儿源;Et,喵喵拳;Es,Dehunters;Ep,马騳骉;Eo,秋闪磕头;En,只因那時年少,波爺丶;El,零距离冲锋;Ej,張氏情歌,薇琪尔的怠惰;Ei,两米七",["冰霜之刃"] = "Ey,洛戈什之翼;Er,亿猫丶,大侠任我行;Eq,傲雪狂歌;Ei,寧負",["红云台地"] = "Ey,红皮鸭子;Es,青囊于心丶;En,Matriix",["太阳之井"] = "Ey,曾经沧海;Ew,瓦嘎;Ev,若然丶",["神圣之歌"] = "Ey,咕藤诚;Ew,馒萌;Es,萨拉揚;Ei,脆皮小熊猫",["风行者"] = "Ey,殇魂残影;Ei,伊生",["血顶"] = "Ey,追昔",["寒冰皇冠"] = "Ey,灵溪;Ep,放飞自我;Em,Bronya;El,颖悦",["熵魔"] = "Ey,菜也快乐着;Eq,黑色柳丁;Ej,杀无尽",["影牙要塞"] = "Ey,飞奔的面包",["芬里斯"] = "Ey,宇宙少女程潇;Eh,Linyolol",["千针石林"] = "Ey,艾尔的战歌;Ei,艾尔的静谧",["阿曼尼"] = "Ey,Gxtv;Eo,英俊的阿昆达",["???"] = "Ey,伊康美宝;Ex,反扒大队,起手开爆发,不必记得我;Ew,无奈;Et,我是大好人;Es,Meeqaq",["万色星辰"] = "Ex,小狼莉子;Ep,我有个苹果",["夏维安"] = "Ex,流刃若火丶",["莱索恩"] = "Ex,武器器",["卡德罗斯"] = "Ex,小米魔月",["安苏"] = "Ex,铁铮,鲟将军,剑啸浮生,梦里寻悦丶;Ew,宝宝不见了,空心白菜,烈焰丨上帝;Ev,一箭丨随风;Et,;Es,汇仁肾宝片;Er,君无斩,嚣戰,氮氧化物;Ep,寒鸦哀鸣,咬死你的狗,皮皮摧心魔;Eo,天天宏;Em,圣光治愈你;El,喔喔嘛嘛;Ek,血沸丶,星空召唤师;Ej,Luckyclover;Eh,呆萌乄叔,奥卡姆剃刀君",["鬼雾峰"] = "Ex,丶浅夜;Eq,Nonowu;En,葡萄灬紫;Ek,Rapple,豆奶火,汐夜梦魇;Eh,懵悠悠",["奥达曼"] = "Ex,Feuxfollets;Eu,Sicilienne;Er,Hypnoc",["银松森林"] = "Ex,妙脆角斗士;Er,紫贝;El,孤峰无伴",["阿纳克洛斯"] = "Ex,贼可爱;Es,苍生灬颤栗;Er,恶魔喵;Eo,芒果绵绵冰;En,幸福的蜗牛;Eh,月陸",["阿克蒙德"] = "Ex,花亦殇;Eu,丶着迷于你;El,丶清柠咖啡;Ek,Damage",["燃烧平原"] = "Ex,小白丶快点跑",["萨尔"] = "Ex,車大黑;Eq,酋弥杏眼;Ej,我冰箱了",["熔火之心"] = "Ex,涂胶于两面;Ep,钺川;En,绝望小熊,丶火辣辣",["风暴之鳞"] = "Ex,播种与收获;Ev,灬小悪梦",["狂热之刃"] = "Ex,灼灼桃花凉;Ew,丶阿尓萨斯,泰丶兰德;Ev,超萌小正太;Eu,灬百年孤独;Er,顶呱呱阿;Em,犬昔;El,甜甜的小白牛;Ej,笑依然,莉丽斯",["黑暗魅影"] = "Ex,牛豆;Es,阿德;Ej,范大鹏有点方",["霜之哀伤"] = "Ex,贞姬;Et,御姬,Colazero;Ep,御神子姬命;El,晨曦之徒;Ek,哥哥来咧;Ej,菲歐娜",["海加尔"] = "Ex,薇姐",["阿比迪斯"] = "Ew,阿方丶",["达尔坎"] = "Ew,五月丶,采薇在云间丶;Ei,丶采薇",["德拉诺"] = "Ew,不知其二",["山丘之王"] = "Ew,风焱;Ev,冥牙,神经科陈主任",["蜘蛛王国"] = "Ew,斯莫德尔,大鱼海棠;Er,云中城小布丁;Ep,德来也;Ej,被抓住的咸鱼;Ei,若蓝",["阿卡玛"] = "Ew,灬黑咖啡灬,灬紫咖啡灬;Er,幽暗偷腥贼,幽暗偷心贼",["冰川之拳"] = "Ew,八未央",["银月"] = "Ew,法糸;Eo,萊茵",["雷克萨"] = "Ew,破碎的面具",["奥杜尔"] = "Ew,小樱桃;Eq,;Ei,小豪豪",["范克里夫"] = "Ew,甜蜜樱桃;Ei,判官",["破碎岭"] = "Ew,执念大魔王;En,铁大妈;Ek,迷茫的尛兔;Ej,青风逐羽",["血牙魔王"] = "Ew,咪咪萌大奶",["丹莫德"] = "Ew,亓晓;El,我不是圆的",["双子峰"] = "Ev,Gemiini",["希雷诺斯"] = "Ev,万人骑",["暗影议会"] = "Ev,蔡校花",["阿尔萨斯"] = "Ev,爆米花老詹;Er,Wartrigger,诬语",["玛法里奥"] = "Ev,兰博基妮",["巫妖之王"] = "Ev,霜影丶;Et,霆哥;Eo,西西小红手;Eh,盖世英雄灬",["弗塞雷迦"] = "Ev,彩虹冰点",["耳语海岸"] = "Ev,给我放手",["红龙军团"] = "Ev,艾尔薇特;Es,取个名字狠蒗;Er,姜还是老的辣;Ej,Predatory",["奥拉基尔"] = "Eu,晕头灬转向",["艾维娜"] = "Eu,叶律云;Er,兰迪丶语风;El,風起的憐惜;Ei,詩琪,消愁",["爱斯特纳"] = "Eu,霹雳丘秋",["诺兹多姆"] = "Eu,八点二十;En,洛蕾尼尔",["巴纳扎尔"] = "Eu,昧芯",["祖阿曼"] = "Eu,沐雨丶橙风",["白骨荒野"] = "Eu,Esgood;Es,新人中单;Eq,王丶重阳",["亡语者"] = "Eu,房飞冯",["洛萨"] = "Eu,大爷丶来玩呀",["永恒之井"] = "Eu,上帝真惩戒;Et,小玉米冫,灵打拯救世界,难过美人关;Ek,黑白大彩电",["回音山"] = "Eu,绮里嘉,明天姗姗;Er,旅立的风;Eq,女人的香气;Ep,八级灬大狂风;En,柯德平;Ek,斯提克斯;Ej,Leserein;Eh,一只肥仔",["雷霆之王"] = "Eu,徐州柴火",["死亡熔炉"] = "Eu,想好了再说;Et,这哪扛得住啊",["麦维影歌"] = "Eu,酒肉穿肠过;En,泡椒小花生",["托尔巴拉德"] = "Eu,听雨丶刘;Es,Deathbrea",["诺森德"] = "Eu,改名出奇迹",["烈焰峰"] = "Eu,Otoha;Et,情意绵绵;Eo,Mineva;En,白发魔法;Ek,没盾开盾墙",["亚雷戈斯"] = "Et,血狱血狱;Es,香橙面包;Eh,断肠",["幽暗沼泽"] = "Et,快让我吸猫;Er,最重要的老婆;Ek,吉哥哥",["古尔丹"] = "Et,燃烧绵绵;En,白色恶魔;Ei,凉雾",["图拉扬"] = "Et,瘦成两百斤;Es,雅欧蕾希尔,小麦色",["哈卡"] = "Et,覇波尔奔;Em,熊猫奶盖乌龙;Ek,五十亲一口",["菲拉斯"] = "Et,魔道刺靑;Es,魔道刺青;Ei,",["密林游侠"] = "Et,抠咔妖;Ek,哼哼我的嘿",["天空之墙"] = "Et,珠圆玉润;Es,鬼灬牛;En,Excarliber",["玛洛加尔"] = "Et,小小木屐;El,丿灬迷鹿",["斯克提斯"] = "Es,Shuna,五行会宁静,不要太潇洒;Er,疯不觉灬;Eo,一记寒冰贱;Ek,赖美云丷;Ei,遗忘灬时光",["戈提克"] = "Es,咕德猫宁",["菲米丝"] = "Es,徽因丶;Ei,Purplee",["深渊之巢"] = "Es,幻影斧",["符文图腾"] = "Es,冰飞电;Eo,朴昭贤;Em,快乐的牛牛",["耐奥祖"] = "Es,暗之忍杀;Ep,倾城琉璃",["遗忘海岸"] = "Es,红山擀面皮;Ej,剑春归花残梦;Ei,刘振",["苏塔恩"] = "Es,毁灭苍炎;Eo,绿度母",["地狱咆哮"] = "Es,天空无我",["鹰巢山"] = "Es,傻傻牛妹妹",["勇士岛"] = "Es,白羊大领主;Eq,拽小熊兔十月;En,宝宝霜",["玛里苟斯"] = "Es,几度红尘,麦笛文的男宠;Eo,天秤座卐暗;Eh,芸七彩",["索瑞森"] = "Er,兰猫;Ei,都是世界的错,非攻",["瓦里玛萨斯"] = "Er,愁惆;Eo,晴耕雨读",["军团要塞"] = "Er,清馨",["萨菲隆"] = "Er,毗奈耶;Eq,星野丨琉璃;Ek,有的放矢",["龙骨平原"] = "Er,Formyhorde;El,拾意;Ek,樱丶吹雪;Eh,愣愣",["末日祷告祭坛"] = "Er,桃芝灬夭夭;Ek,丶干炸熊咕",["外域"] = "Er,九姑娘",["永夜港"] = "Eq,傲世寒霜;Eo,苏鲁德",["玛瑟里顿"] = "Eq,毒瘤的二一",["利刃之拳"] = "Eq,貮杉;Eo,我会飞",["克苏恩"] = "Eq,仁者乄无敌",["迦顿"] = "Ep,白昼夜行,湯姆先森",["伊利丹"] = "Ep,屍體發火;Eh,Kazs",["布莱恩"] = "Ep,木槿潇湘",["扎拉赞恩"] = "Ep,水漪月",["安纳塞隆"] = "Ep,极速小野",["血吼"] = "Ep,小丑还魂;Ei,上辈子的情人;Eh,符华",["語風[TW]"] = "Ep,楊爸爸",["伊萨里奥斯"] = "Ep,敬爱的楠大大;Em,彎彎",["梅尔加尼"] = "Ep,灰灰先森;Ej,喜来宝",["铜龙军团"] = "Ep,曲无忆,莱殴瑟拉斯;El,浮沉丶",["朵丹尼尔"] = "Ep,小秋儿哈;Em,达尔达尼央",["冬泉谷"] = "Ep,一秒大大头大",["艾萨拉"] = "Eo,地狱的梦魇",["自由之风"] = "Eo,唐玄藏唐长老;Ei,唧唧",["鲜血熔炉"] = "Eo,御坂美琴;Ej,让包子飞",["黑石尖塔"] = "Eo,党党是翘臀",["阿拉希"] = "Eo,苍牧;En,气球一元一个",["守护之剑"] = "Eo,吴彦诅",["通灵学院"] = "Eo,升职弃官",["火羽山"] = "Eo,御风之徒",["卡德加"] = "Eo,Kungen",["阿拉索"] = "Eo,阿修修十五;Eh,残忍的软泥兔",["盖斯"] = "En,三千世界",["生态船"] = "En,苏绫;Ej,六橙合体丶",["伊森德雷"] = "En,西里橘",["远古海滩"] = "En,萝珂塔;Ei,Flavia",["提瑞斯法"] = "En,王炸灬",["灰谷"] = "En,泉丶此方;Em,Iyrel;Ei,迦顿男爵",["大地之怒"] = "En,鸥鹭;Ej,包养小萌宠",["奥尔加隆"] = "Em,最是寻常梦,药家鑫灬;Ei,潜意识回忆",["斩魔者"] = "Em,百山惊鸿",["基尔加丹"] = "Em,镝剑",["伊莫塔尔"] = "Em,给我个机会",["世界之树"] = "Em,故人何在;Ei,膨胀",["耐普图隆"] = "Em,双子丶瓦莉拉",["风暴之怒"] = "Em,打断我来;El,Deathvalkyri;Ej,污丶云",["黑暗之门"] = "Em,手无扶鸡之力",["麦姆"] = "Em,老牛很忙",["拉文霍德"] = "Em,大丨黒丨手",["暮色森林"] = "Em,筱雅沐馡",["诺莫瑞根"] = "Em,丑的无语",["斯坦索姆"] = "El,亚汉",["金度"] = "El,挽手说梦话丶",["能源舰"] = "Ek,渡我被身子",["时光之穴"] = "Ek,Boombiubiu",["艾莫莉丝"] = "Ek,铁心",["埃克索图斯"] = "Ek,冷色调调,猫污猫",["提尔之手"] = "Ek,一刀繚乱;Ej,Kderhzdd;Ei,柠檬小丸子",["克洛玛古斯"] = "Ek,一本初心",["玛诺洛斯"] = "Ek,Revengor",["雷霆号角"] = "Ek,我叫亲亲",["月神殿"] = "Ek,笔冢墨池",["加尔"] = "Ek,孤独狼人",["红龙女王"] = "Ek,就是不可能;Eh,啼笑木偶",["麦迪文"] = "Ej,最强之刃",["雷霆之怒"] = "Ej,谜阿丶,林丶熙娜;Ei,尘灬风暴烈酒,小跳蛙",["战歌"] = "Ej,糖糖卟甜",["逐日者"] = "Ej,王银圣",["库尔提拉斯"] = "Ej,燃烟",["埃加洛尔"] = "Ei,朵朵菊花开",["暗影迷宫"] = "Ei,赵依然",["黑暗虚空"] = "Ei,长歌藐倥偬",["壁炉谷"] = "Eh,Arenge",["日落沼泽"] = "Eh,盛乄夏",["风暴峭壁"] = "Eh,奶茶店的萝莉",["米奈希尔"] = "Eh,送来送去"};
local start = { year = 2018, month = 8, day = 3, hour = 7, min = 0, sec = 0 }
local now = time()
local player_shown = {}
U1Donators.players = player_shown

local topNamesOrder = {} for i, name in ipairs({ strsplit(',', topNames) }) do topNamesOrder[name] = i end

local realms, players, player_days = {}, {}, {}
local base64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
local function ConvertDonators(day_realm_players)
    if not day_realm_players then return end
    for realm, allday in pairs(day_realm_players) do
        if not tContains(realms, realm) then table.insert(realms, realm) end
        for _, oneday in ipairs({strsplit(';', allday)}) do
            local date;
            for i, player in ipairs({strsplit(',', oneday)}) do
                if i == 1 then
                    local dec = (base64:find(player:sub(1,1)) - 1) * 64 + (base64:find(player:sub(2,2)) - 1)
                    local y, m, d = floor(dec/12/31)+2018, floor(dec/31)%12+1, dec%31+1
                    date = format("%04d-%02d-%02d", y, m, d)
                else
                    local fullname = player .. '-' .. (realm:gsub("%[.-%]", ""))
                    table.insert(players, fullname)
                    player_days[fullname] = date
                    player_shown[fullname] = topNamesOrder[fullname] or 0
                end
            end
        end
    end
end
ConvertDonators(recentDonators)
recentDonators = nil
ConvertDonators(U1.historyDonators)
U1.historyDonators = nil

table.sort(players, function(a, b)
    local order1 = topNamesOrder[a] or 9999
    local order2 = topNamesOrder[b] or 9999
    if order1 ~= order2 then return order1 < order2 end
    local _, r1 = strsplit("-", a)
    local _, r2 = strsplit("-", b)
    if r1 ~= r2 then
        if r1 == '???' then return false
        elseif r2 == '???' then return true
        else return r1 < r2; end
    end
    local day1 = player_days[a]
    local day2 = player_days[b]
    if day1 ~= day2 then return day1 > day2 end
    return a < b
end)
-- 排完序就不需要了
topNames = nil
topNamesOrder = nil

function U1Donators:CreateFrame()
    local f = WW:Frame("U1DonatorsFrame", UIParent, "BasicFrameTemplateWithInset"):Size(320, 500):TR(U1Frame, "TL", -10, 0):SetToplevel(1):SetFrameStrata("DIALOG")

    f.TitleText:SetText("爱不易的捐助者，谢谢你们")
    f.InsetBg:SetPoint("TOPLEFT", 4, -50)
    CoreUIMakeMovable(f)

    local scroll = CoreUICreateHybridStep1(nil, f(), nil, true, true, nil)
    WW(scroll):TL(f.InsetBg, 3, -3):BR(f.InsetBg, -2-21, 2):un() --:TL(3, -20)
    f.scroll = scroll

    local headn = TplColumnButton(f, nil, 22):SetWidth(108):SetText("玩家主角色"):SetScript("OnClick", noop):un()
    WW(headn:GetFontString()):SetFontHeight(14):un()
    local heads = TplColumnButton(f, nil, 22):SetWidth(80):SetText("服务器"):SetScript("OnClick", noop):un()
    WW(heads:GetFontString()):SetFontHeight(14):un()
    local headd = TplColumnButton(f, nil, 22):SetWidth(100):SetText("捐助时间"):SetScript("OnClick", noop):un()
    WW(headd:GetFontString()):SetFontHeight(14):un()
    CoreUIAnchor(f, "TOPLEFT", "TOPLEFT", 8, -30, "LEFT", "RIGHT", 0, 0, headn, heads, headd)

    local function fix_text_width(obj)
      obj:GetFontString():SetAllPoints()
    end

    scroll.creator = function(self, index, name)
      local row = WW(self.scrollChild):Button(name):LEFT():RIGHT():Size(0, 20)
      row:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], 'ADD')

      row.name = row:Button():Size(100, 20):EnableMouse(false):SetButtonFont(U1FCenterTextMid):SetText(111):GetButtonText():SetJustifyH("Center"):up()
      row.server = row:Button():Size(75, 20):EnableMouse(false):SetButtonFont(U1FCenterTextTiny):SetText(111):GetButtonText():SetJustifyH("Right"):up()
      row.firstdate = row:Button():Size(90, 20):EnableMouse(false):SetButtonFont(U1FCenterTextTiny):SetText(333):GetButtonText():SetJustifyH("Right"):up()

      fix_text_width(row.name)
      fix_text_width(row.server)
      fix_text_width(row.firstdate)

      CoreUIAnchor(row, "LEFT", "LEFT", 5, 0, "LEFT", "RIGHT", 5, 0, row.name, row.server, row.firstdate)
      return row:un()
    end

    scroll.getNumFunc = function()
      return #players
    end

    scroll.updateFunc = function(self, row, index)
      row.index = index
      local name, realm = strsplit('-', players[index])
      row.name:SetText(name)
      row.server:SetText(realm)
      row.firstdate:SetText(player_days[players[index]]);
      --row.name:GetFontString():SetTextColor(1,1,1)
      --local date_fmt = '%Y/%m/%d'
      --local txt = date(date_fmt, time())
      --row.firstdate:SetText(txt)
    end

    CoreUICreateHybridStep2(scroll, 0, 0, "TOPLEFT", "TOPLEFT", 0)

    f:Hide();
    return f()
end

CoreOnEvent("PLAYER_ENTERING_WORLD", function()
    local origs = {}
    local addMessageReplace = function(self, msg, ...)
        msg = msg and tostring(msg) or ""
        local h, t, part1, fullname, part2 = msg:find("(\124Hplayer:(.-):.-:.-:.-\124h%[)(\124c.........-\124r%]\124h)")
        if fullname and ((U1Donators and U1Donators.players[fullname]) or (U1STAFF and U1STAFF[fullname])) then
            --local _, height = self:GetFont()
            msg = msg:sub(1,h-1) .. part1 .. '\124TInterface\\AddOns\\!!!163UI!!!\\Textures\\UI2-logo:' .. (13) .. '\124t' .. part2 .. msg:sub(t+1);
        end
        origs[self](self, msg, ...)
    end
    WithAllChatFrame(function(cf)
        if cf:GetID() == 2 then return end
        origs[cf] = cf.AddMessage
        cf.AddMessage = addMessageReplace
    end)
    return "remove"
end)