// main_tiny.dart  --  This file is part of tiny_computer.
                                                                        
// Copyright (C) 2023 Caten Hu                                          
                                                                        
// Tiny Computer is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published    
// by the Free Software Foundation, either version 3 of the License,    
// or any later version.                               
                                                                         
// Tiny Computer is distributed in the hope that it will be useful,          
// but WITHOUT ANY WARRANTY; without even the implied warranty          
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.              
// See the GNU General Public License for more details.                 
                                                                     
// You should have received a copy of the GNU General Public License    
// along with this program.  If not, see http://www.gnu.org/licenses/.


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
//import 'dart:convert';

//import 'package:flutter/services.dart';

import 'package:clipboard/clipboard.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:xterm/xterm.dart';
//import 'package:xterm/flutter.dart';

import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';

import 'workflow.dart';


class MyTinyApp extends StatelessWidget {
  const MyTinyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return MaterialApp(
            title: 'Tiny Computer',
            theme: ThemeData(
              colorScheme: lightDynamic,
              useMaterial3: true,
              //fontFamily: "FiraCode",
            ),
            darkTheme: ThemeData(
              colorScheme: darkDynamic,
              useMaterial3: true,
              //fontFamily: "FiraCode",
            ),
            home: const MyHomePage(title: 'Tiny Computer'),
          );
        }
    );
  }
}


class FakeLoadingStatus extends StatefulWidget {
  const FakeLoadingStatus({super.key});

  @override
  State<FakeLoadingStatus> createState() => _FakeLoadingStatusState();
}

class _FakeLoadingStatusState extends State<FakeLoadingStatus> {

  double _progressT = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progressT += 0.1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(value: 1 - pow(10, _progressT / -300).toDouble());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {

  final List<bool> _expandState = [false, false, false, false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: const EdgeInsets.all(0),
      expansionCallback: (panelIndex, isExpanded) {
      setState(() {
        _expandState[panelIndex] = isExpanded;
      });
    },children: [
      ExpansionPanel(
        isExpanded: _expandState[0],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("高级设置"), subtitle: Text("修改后重启生效"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          OutlinedButton(style: D.commandButtonStyle, child: const Text("重置启动命令"), onPressed: () {
            showDialog(context: context, builder: (context) {
              return AlertDialog(title: const Text("注意"), content: const Text("是否重置启动命令？"), actions: [
                TextButton(onPressed:() {
                  Navigator.of(context).pop();
                }, child: const Text("取消")),
                TextButton(onPressed:() async {
                  await Util.setCurrentProp("boot", D.boot);
                  G.bootTextChange.value = !G.bootTextChange.value;
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                }, child: const Text("是")),
              ]);
            });
          }),
          SizedBox.fromSize(size: const Size.square(8)),
          TextFormField(maxLines: null, initialValue: Util.getCurrentProp("name"), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "容器名称"), onChanged: (value) async {
            await Util.setCurrentProp("name", value);
            //setState(() {});
          }),
          SizedBox.fromSize(size: const Size.square(8)),
          ValueListenableBuilder(valueListenable: G.bootTextChange, builder:(context, v, child) {
            return TextFormField(maxLines: null, initialValue: Util.getCurrentProp("boot"), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "启动命令"), onChanged: (value) async {
              await Util.setCurrentProp("boot", value);
            });
          }),
          SizedBox.fromSize(size: const Size.square(8)),
          TextFormField(maxLines: null, initialValue: Util.getCurrentProp("vnc"), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "vnc启动命令"), onChanged: (value) async {
            await Util.setCurrentProp("vnc", value);
          }),
          SizedBox.fromSize(size: const Size.square(8)),
          const Divider(height: 2, indent: 8, endIndent: 8),
          SizedBox.fromSize(size: const Size.square(16)),
          const Text("你可以在当前所有同一网络下的设备（如：连接同一路由器的手机，电脑等）里使用小小电脑。\n\n将下面的链接复制到其他设备，在其他设备上把链接localhost字样改为当前设备的IP地址（可以通过快捷指令查看，格式类似192.168.x.x），然后使用浏览器打开链接即可。"),
          SizedBox.fromSize(size: const Size.square(16)),
          TextFormField(maxLines: null, initialValue: Util.getCurrentProp("vncUrl"), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "网页跳转地址"), onChanged: (value) async {
            await Util.setCurrentProp("vncUrl", value);
          }),
          SizedBox.fromSize(size: const Size.square(8)),
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[1],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("全局设置"), subtitle: Text("在这里关广告、开启终端编辑"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextFormField(autovalidateMode: AutovalidateMode.onUserInteraction, initialValue: (Util.getGlobal("termMaxLines") as int).toString(), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "终端最大行数(重启软件生效)"), readOnly: Util.shouldWatchAds(D.adsRequired["changeTermMaxLines"]!),
            keyboardType: TextInputType.number,
            onTap: () {
              if (Util.shouldWatchAds(D.adsRequired["changeTermMaxLines"]!)) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("观看六次视频广告永久解锁><"))
                );
              }
            },
            validator: (value) {
              return Util.validateBetween(value, 1024, 2147483647, () async {
                await G.prefs.setInt("termMaxLines", int.parse(value!));
              });
            },),
          SizedBox.fromSize(size: const Size.square(16)),
          TextFormField(autovalidateMode: AutovalidateMode.onUserInteraction, initialValue: (Util.getGlobal("defaultAudioPort") as int).toString(), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "pulseaudio接收端口"),
            keyboardType: TextInputType.number,
            validator: (value) {
              return Util.validateBetween(value, 0, 65535, () async {
                await G.prefs.setInt("defaultAudioPort", int.parse(value!));
              });
            }
          ),
          SizedBox.fromSize(size: const Size.square(16)),
          SwitchListTile(title: const Text("关闭横幅广告"), value: Util.getGlobal("isBannerAdsClosed") as bool, onChanged:(value) {
            if (value && Util.shouldWatchAds(D.adsRequired["closeBannerAds"]!)) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("观看五次视频广告永久解锁><"))
              );
              return;
            }
            G.prefs.setBool("isBannerAdsClosed", value);
            setState(() {
              G.bannerAdsChange.value = !G.bannerAdsChange.value;
            });
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("启用终端"), value: Util.getGlobal("isTerminalWriteEnabled") as bool, onChanged:(value) {
            if (value && Util.shouldWatchAds(D.adsRequired["enableTerminalWrite"]!)) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text("观看两次视频广告永久解锁><"), action: SnackBarAction(label: "啊?", onPressed: () {
                  G.prefs.setBool("isTerminalWriteEnabled", value);
                  setState(() {});
                },))
              );
              return;
            }
            G.prefs.setBool("isTerminalWriteEnabled", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("启用终端小键盘"), value: Util.getGlobal("isTerminalCommandsEnabled") as bool, onChanged:(value) {
            if (value && Util.shouldWatchAds(D.adsRequired["enableTerminalCommands"]!)) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("观看三次视频广告永久解锁><"))
              );
              return;
            }
            G.prefs.setBool("isTerminalCommandsEnabled", value);
            setState(() {
              G.terminalPageChange.value = !G.terminalPageChange.value;
            });
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("终端粘滞键"), value: Util.getGlobal("isStickyKey") as bool, onChanged:(value) {
            G.prefs.setBool("isStickyKey", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("屏幕常亮"), value: Util.getGlobal("wakelock") as bool, onChanged:(value) {
            G.prefs.setBool("wakelock", value);
            WakelockPlus.toggle(enable: value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          const Divider(height: 2, indent: 8, endIndent: 8),
          SizedBox.fromSize(size: const Size.square(16)),
          const Text("以下选项修改后将在下次启动软件时生效。"),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("开启时启动图形界面"), value: Util.getGlobal("autoLaunchVnc") as bool, onChanged:(value) {
            G.prefs.setBool("autoLaunchVnc", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("重新安装引导包"), value: Util.getGlobal("reinstallBootstrap") as bool, onChanged:(value) {
            G.prefs.setBool("reinstallBootstrap", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("getifaddrs桥接"), subtitle: const Text("修复安卓13设备getifaddrs无权限"), value: Util.getGlobal("getifaddrsBridge") as bool, onChanged:(value) {
            G.prefs.setBool("getifaddrsBridge", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("伪装系统为UOS"), subtitle: const Text("修复UOS微信无法启动"), value: Util.getGlobal("uos") as bool, onChanged:(value) {
            G.prefs.setBool("uos", value);
            setState(() {});
          },),
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[2],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("相机推流"), subtitle: Text("实验性功能"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          const Text("成功启动推流后可以点击快捷指令\"拉流测试\"并前往图形界面查看效果。\n注意这并不能为系统创建一个虚拟相机；\n另外使用相机是高耗电行为，不用时需及时关闭。"),
          const SizedBox.square(dimension: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 4.0, runSpacing: 4.0, children: [
            OutlinedButton(style: D.commandButtonStyle, child: const Text("申请相机权限"), onPressed: () {
              Permission.camera.request();
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("申请麦克风权限"), onPressed: () {
              Permission.microphone.request();
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("查看输出"), onPressed: () {
              if (G.streamingOutput == "") {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("无输出"))
                );
                return;
              }
              showDialog(context: context, builder: (context) {
                return AlertDialog(content: SingleChildScrollView(child:
                  Text(G.streamingOutput)), actions: [
                TextButton(onPressed:() {
                  FlutterClipboard.copy(G.streamingOutput).then(( value ) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已复制")));
                  });
                  Navigator.of(context).pop();
                }, child: const Text("复制")),
                TextButton(onPressed:() {
                  Navigator.of(context).pop();
                }, child: const Text("取消")),
              ]);
              });
            }),
          ]),
          const SizedBox.square(dimension: 16),
          TextFormField(maxLines: null, initialValue: Util.getGlobal("defaultFFmpegCommand") as String, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ffmpeg推流命令"), readOnly: Util.shouldWatchAds(D.adsRequired["changeFFmpegCommand"]!),
            onTap: () {
              if (Util.shouldWatchAds(D.adsRequired["changeFFmpegCommand"]!)) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("观看八次视频广告永久解锁><"))
                );
              }
            },
            onChanged: (value) async {
              await G.prefs.setString("defaultFFmpegCommand", value);
            },
          ),
          const SizedBox.square(dimension: 16),
          SwitchListTile(title: const Text("启动推流服务器"), subtitle: const Text("mediamtx"), value: G.isStreamServerStarted, onChanged:(value) {
            switch (value) {
              case true: {
                G.streamServerPty = Pty.start("/system/bin/sh");
                G.streamServerPty.write(const Utf8Encoder().convert("${G.dataPath}/bin/mediamtx ${G.dataPath}/bin/mediamtx.yml\nexit\n"));
                G.streamServerPty.exitCode.then((value) {
                  G.isStreamServerStarted = false;
                  setState(() {});
                });
              }
              break;
              case false: {
                G.streamServerPty.write(const Utf8Encoder().convert("\x03exit\n"));
              }
              break;
            }
            G.isStreamServerStarted = value;
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("启动推流"), value: G.isStreaming, onChanged:(value) {
            switch (value) {
              case true: {
                FFmpegKit.execute(Util.getGlobal("defaultFFmpegCommand") as String).then((session) {
                  session.getOutput().then((value) async {
                    G.isStreaming = false;
                    G.streamingOutput = value??"";
                    setState(() {});
                  });
                });
              }
              break;
              case false: {
                FFmpegKit.cancel();
              }
              break;
            }
            G.isStreaming = value;
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(8))
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[3],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("文件访问"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          const Text("通过这里获取更多文件权限，以实现对特殊目录的访问。"),
          SizedBox.fromSize(size: const Size.square(16)),
          Wrap(alignment: WrapAlignment.center, spacing: 4.0, runSpacing: 4.0, children: [
            OutlinedButton(style: D.commandButtonStyle, child: const Text("申请存储权限"), onPressed: () {
              Permission.storage.request();
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("申请所有文件访问权限"), onPressed: () {
              Permission.manageExternalStorage.request();
            }),
          ]),
          SizedBox.fromSize(size: const Size.square(16)),
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[4],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("virgl加速"), subtitle: Text("实验性功能"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          const Text("""virgl加速可部分利用设备GPU提升系统图形处理表现，但由于设备差异也可能导致容器系统及软件运行不稳定甚至异常退出。

请先开启测试按钮启动virgl服务器，如果按钮没有自动关闭说明至少启动没问题；

不过运行情况依然无法保证。
"""),
          SizedBox.fromSize(size: const Size.square(16)),
          TextFormField(maxLines: null, initialValue: Util.getGlobal("defaultVirglCommand") as String, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "virgl服务器参数"),
            onChanged: (value) async {
              await G.prefs.setString("defaultVirglCommand", value);
            },
          ),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("测试"), subtitle: const Text("启动virgl_test_server"), value: G.isVirglServerStarted, onChanged:(value) {
            switch (value) {
              case true: {
                G.virglServerPty = Pty.start("/system/bin/sh");
                G.virglServerPty.write(const Utf8Encoder().convert("export CONTAINER_DIR=${G.dataPath}/containers/${G.currentContainer}\n${G.dataPath}/bin/virgl_test_server ${Util.getGlobal("defaultVirglCommand")}\nexit\n"));
                G.virglServerPty.exitCode.then((value) {
                  G.isVirglServerStarted = false;
                  setState(() {});
                });
              }
              break;
              case false: {
                G.virglServerPty.write(const Utf8Encoder().convert("\x03exit\n"));
              }
              break;
            }
            G.isVirglServerStarted = value;
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(16)),
          TextFormField(maxLines: null, initialValue: Util.getGlobal("defaultVirglOpt") as String, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "图形环境变量"),
            onChanged: (value) async {
              await G.prefs.setString("defaultVirglOpt", value);
            },
          ),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("启用virgl加速"), subtitle: const Text("下次启动时生效"), value: Util.getGlobal("virgl") as bool, onChanged:(value) {
            if (value && Util.shouldWatchAds(D.adsRequired["enableVirgl"]!)) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("观看十次视频广告永久解锁><"))
              );
              return;
            }
            G.prefs.setBool("virgl", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(16)),
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[5],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("跨架构/跨系统支持"), subtitle: Text("实验性功能"),);
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          const Text("""使用box86/box64运行x86/x64架构的程序，或使用wine运行windows程序。

运行windows程序需要经过架构和系统两层模拟，不要对运行速度抱有期待。程序崩溃也是常有的。

你需要耐心。即使图形界面什么也没显示。看看终端，还在继续输出吗？还是停止在某个报错？

如果不耐烦可以去看个广告消磨时间（bushi）

或者寻找该windows软件官方是否提供linux arm64版本。

给高级用户的注意事项：
跨架构/跨系统提供类似binfmt_misc的支持。
你可以直接执行x86或x64的elf（系统会自动调用box86/box64），也可以直接执行exe文件（系统会自动调用wine64）。
前提是这些文件拥有可执行权限。"""),
          SizedBox.fromSize(size: const Size.square(8)),
          Wrap(alignment: WrapAlignment.center, spacing: 4.0, runSpacing: 4.0, children: [
            OutlinedButton(style: D.commandButtonStyle, child: const Text("安装box86和box64"), onPressed: () {
              Util.termWrite("bash ~/.local/share/tiny/extra/install-box");
              G.pageIndex.value = 0;
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("安装wine"), onPressed: () async {
              if (!await File("${G.dataPath}/tiny/cross/box64").exists()) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("请先安装box86/box64"))
                );
                return;
              }
              Util.termWrite("bash ~/.local/share/tiny/extra/install-wine");
              G.pageIndex.value = 0;
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("安装dxvk"), onPressed: () async {
              if (!G.wasWineEnabled) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("请启用wine后重试"))
                );
                return;
              }
              Util.termWrite("bash ~/.local/share/tiny/extra/install-dxvk");
              G.pageIndex.value = 0;
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("移除所有安装"), onPressed: () async {
              if (G.wasBoxEnabled) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("请关闭跨架构支持后重试"))
                );
                return;
              }
              Util.termWrite("rm -rf ~/.local/share/tiny/cross");
              G.pageIndex.value = 0;
            }),
            OutlinedButton(style: D.commandButtonStyle, child: const Text("清空wine数据"), onPressed: () async {
              Util.termWrite("rm -rf ~/.wine");
              G.pageIndex.value = 0;
            }),
          ]),
          SizedBox.fromSize(size: const Size.square(16)),
          const Divider(height: 2, indent: 8, endIndent: 8),
          SizedBox.fromSize(size: const Size.square(16)),
          const Text("""开启wine后的常用指令，点击后前往图形界面耐心等待。

任意程序启动参考时间：
虎贲T7510 6GB 超过一分钟
骁龙870 12GB 约10秒
骁龙8gen3 不支持32位 可能不可用

初始化时间：
可能比本软件初始化还长
"""),
          SizedBox.fromSize(size: const Size.square(8)),
          Wrap(alignment: WrapAlignment.center, spacing: 4.0, runSpacing: 4.0, children: D.wineCommands.asMap().entries.map<Widget>(
            (e) {
              return OutlinedButton(style: D.commandButtonStyle, child: Text(e.value["name"]!), onPressed: () {
                Util.termWrite("${e.value["command"]!} &");
                G.pageIndex.value = 0;
              });
            }
          ).toList()),
          SizedBox.fromSize(size: const Size.square(16)),
          const Divider(height: 2, indent: 8, endIndent: 8),
          SizedBox.fromSize(size: const Size.square(16)),
          const Text("以下选项修改后将在下次启动软件时生效。"),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("启用box86/box64"), subtitle: const Text("运行跨架构软件"), value: Util.getGlobal("isBoxEnabled") as bool, onChanged:(value) async {
            //检测box64是否存在，存在才开启
            if (value && !await File("${G.dataPath}/tiny/cross/box64").exists()) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("请先安装box86/box64"))
              );
              return;
            }
            G.prefs.setBool("isBoxEnabled", value);
            if (!value && Util.getGlobal("isWineEnabled")) {
              G.prefs.setBool("isWineEnabled", false);
            }
            setState(() {});
          },),
          SwitchListTile(title: const Text("启用wine"), subtitle: const Text("运行windows exe软件"), value: Util.getGlobal("isWineEnabled") as bool, onChanged:(value) async {
            //检测wine是否存在且box64是否开启
            if (value && !(Util.getGlobal("isBoxEnabled") && await File("${G.dataPath}/tiny/cross/wine/bin/wine").exists())) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("请先安装wine并启用box86/box64"))
              );
              return;
            }
            Util.execute(value ? """filename="${G.dataPath}/containers/${G.currentContainer}/home/tiny/.bashrc"
command="export PATH=\\\$HOME/.local/share/tiny/cross/wine/bin:\\\$PATH # Auto-generated, do NOT edit"
if ! ${G.dataPath}/busybox grep -qF "\$command" "\$filename"; then
    echo "\$command" >> "\$filename"
fi""" : """filename="${G.dataPath}/containers/${G.currentContainer}/home/tiny/.bashrc"
command="export PATH=\\\$HOME/.local/share/tiny/cross/wine/bin:\\\$PATH # Auto-generated, do NOT edit"
if ${G.dataPath}/busybox grep -qF "\$command" "\$filename"; then
    command="export PATH=\\\$HOME/.local/share/tiny/cross/wine/bin:\\\$PATH \\\\# Auto-generated, do NOT edit"
    ${G.dataPath}/busybox sed -i "\\\\#\$command#d" "\$filename"
fi""");
            G.prefs.setBool("isWineEnabled", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(16)),
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[6],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("高分辨率支持"), subtitle: Text("实验性功能"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          const Text("""为更大的屏幕带来更高清的体验！

注意：
选项开启后显示会变得很大，请在图形界面的左栏设置里手动调整缩放到一个你认为合适的值。

一些软件可能会存在显示问题，或者显示速度变慢。"""),
          SizedBox.fromSize(size: const Size.square(16)),
          TextFormField(maxLines: null, initialValue: Util.getGlobal("defaultHidpiOpt") as String, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "HiDPI环境变量"), readOnly: Util.shouldWatchAds(D.adsRequired["changeHidpiOpt"]!),
            onTap: () {
              if (Util.shouldWatchAds(D.adsRequired["changeHidpiOpt"]!)) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("观看十二次视频广告永久解锁><"))
                );
              }
            },
            onChanged: (value) async {
              await G.prefs.setString("defaultHidpiOpt", value);
            },
          ),
          SizedBox.fromSize(size: const Size.square(8)),
          SwitchListTile(title: const Text("高分辨率支持"), subtitle: const Text("下次启动时生效"), value: Util.getGlobal("isHidpiEnabled") as bool, onChanged:(value) {
            G.prefs.setBool("isHidpiEnabled", value);
            setState(() {});
          },),
          SizedBox.fromSize(size: const Size.square(16)),
        ],))),
      ExpansionPanel(
        isExpanded: _expandState[7],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("广告记录"), subtitle: Text("在这里看广告"));
        }), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          OutlinedButton(child: const Text("看一个广告"), onPressed: () {
              if (AdManager.placements[AdManager.rewardedVideoAdPlacementId]!) {
              AdManager.showAd(AdManager.rewardedVideoAdPlacementId, () {
                final bonus = Util.getRandomBonus();
                Util.applyBonus(bonus);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("你获得了 ${bonus["name"]}*${bonus["amount"]}"))
                );
                setState(() {});
              }, () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("已经看5个广告了, 今天也非常感谢><"))
                );
              });
              }
            }),
            const SizedBox.square(dimension: 8),
            Text(Util.getGlobal("adsBonus").map((element) {
              final e = jsonDecode(element);
              return e["amount"]==0?"":"${e["name"]}*${e["amount"]}\n";
            }).join())
        ],))),
    ],);
  }
}

class InfoPage extends StatefulWidget {
  final bool openFirstInfo;

  const InfoPage({super.key, this.openFirstInfo=false});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final List<bool> _expandState = [false, false, false, false, false];
  
  @override
  void initState() {
    super.initState();
    _expandState[0] = widget.openFirstInfo;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: const EdgeInsets.all(0),
      expansionCallback: (panelIndex, isExpanded) {
        setState(() {
          _expandState[panelIndex] = isExpanded;
        });
      },
    children: [
      ExpansionPanel(
        headerBuilder: (context, isExpanded) {
          return const ListTile(title: Text("使用说明"));
        },
        body: const Padding(padding: EdgeInsets.all(8), child: Text("""
第一次加载大概需要5到10分钟...
正常情况下，加载完成后软件会自动跳转到图形界面

在图形界面时，点击即鼠标左键
双指点击为鼠标右键
双指划动为鼠标滚轮

在图形界面返回，可以回到终端界面和控制界面
你可以在控制界面安装更多软件或者阅读帮助信息

请不要在安装时退出软件

如果过了很长时间都没有加载完成
可以去设置里看看小小电脑占用空间是不是一直没变
如果是说明卡在什么地方了
建议清除本软件数据重来一次

(有一位网友提到过
自己无论怎么清软件数据都装不上
但在重启手机之后就装上了)

一些注意事项：
此软件以GPL协议免费开源
如果是买的就是被骗了, 请举报
源代码在这里: https://github.com/Cateners/tiny_computer
软件也会第一时间在这里更新
请尽可能在这里下载软件, 确保是正版

常见问题：
如果你的系统版本大于等于android 12
可能会在使用过程中异常退出(返回错误码9)
届时本软件会提供方案指引你修复
并不难
但是软件没有权限
不能帮你修复

如果你的系统版本大于等于android 13
那么很可能一些网页应用如jupyter notebook
bilibili客户端等等不可用
可以去全局设置开启getifaddrs桥接

如果你给了存储权限
那么通过主目录下的文件夹
就可以访问手机存储

有一些设备做了更多访问限制
比如下载文件夹可能不可写入
这样会导致把文件保存到下载目录时出现问题
(火狐浏览器可能因此无法下载文件)
不过这个很好解决
换个文件夹保存就行了

如果认为界面大小比例不合适
可以通过调整图形界面左栏设置-高级里的屏幕缩放比例
如果感觉界面卡卡的
可以适当调低图像质量或压缩等级

如果你想安装其他软件
可以使用容器自带的tmoe
但并不保证安装了能用哦
(事实上, 目前容器里的
VSCode、输入法
都是用tmoe安装的
就连系统本身也是用tmoe安装的)

也可以在网上搜索
"ubuntu安装xxx教程"
"linux安装xxx教程"等等
本软件也提供一些基本软件安装按钮
包括图形处理, 视频剪辑, 科学计算相关的软件
稍后你就会看到

如果你需要更多字体
在给了存储权限的情况下
直接将字体复制到手机存储的Fonts文件夹即可
一些常用的办公字体
可以在Windows电脑的C:\\Windows\\Fonts文件夹找到
由于可能的版权问题
软件不能帮你做

关于中文输入的问题
强烈建议不要使用安卓中文输入法直接输入中文
而是使用英文键盘通过容器的输入法(Ctrl+空格切换)输入中文
避免丢字错字

在之前的版本中有网友反馈过这些问题
还请注意：
三星Galaxy S21 Ultra, 安卓13, 黑屏
红米Note 12, 安卓13（miui14）, 黑屏
红米Note 11T Pro+， miui13.0.4，“无法连接”
Vivo Pad，安卓13，看不见鼠标移动（可以去左栏设置开启显示原系统光标替代）
关于这些
我目前没有什么好的解决办法
(毕竟我没有这些设备
也不方便定位原因)
如果你遇到了类似问题
不管解没解决
都可以去https://github.com/Cateners/tiny_computer/issues/留个言

如果软件里有程序正在正常运行
请不要强行关闭本软件
否则可能会损坏容器
特别是在安装某些比较大的软件的时候

感谢使用!

(顺带一提, 全部解压完大概需要4~5GB空间
解压途中占用空间可能更多
请确保有足够的空间
(这样真的Tiny吗><))

"""
        )),
        isExpanded: _expandState[0],
      ),
      ExpansionPanel(
        isExpanded: _expandState[1],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("开源许可"));
        }), body: const Padding(padding: EdgeInsets.all(8), child: Text("""
Flutter, path_provider, webview_flutter, url_launcher, shared_preferences

Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

------------
xterm

The MIT License (MIT)

Copyright (c) 2020 xuty

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

------------
flutter_pty

The MIT License (MIT)

Copyright (c) 2022 xuty

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

------------
permission_handler

MIT License

Copyright (c) 2018 Baseflow

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

------------
http

Copyright 2014, the Dart project authors. 

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google LLC nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

------------
retry

Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

------------
intl

Copyright 2013, the Dart project authors.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google LLC nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

------------
unity_ads_plugin

MIT License

Copyright (c) 2021 Pavel Zaichyk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""))),
      ExpansionPanel(
        isExpanded: _expandState[2],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("隐私政策"));
        }), body: const Padding(padding: EdgeInsets.all(8), child: Text("""
除由Unity提供的广告功能外, 本软件不会收集你的隐私信息。

当然，你在容器系统内部安装或使用的软件行为（包括通过快捷指令）就不受我控制了，我不对其负责。

本软件申请的权限用于以下目的：
文件相关权限：用于系统访问手机目录；
相机和麦克风：用于推流，默认不会开启。

关于广告获取隐私信息的说明, 在第一次看广告时Unity会向你做出告知。
届时你可以选择要向Unity提供哪些信息。
"""))),
      ExpansionPanel(
        isExpanded: _expandState[3],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("服务条款"));
        }), body: const Padding(padding: EdgeInsets.all(8), child: Text("""
小小电脑: 即开即用的类PC环境

版权所有(C) 2023 Caten Hu

本程序是自由软件：你可以再分发之和/或依照由自由软件基金会发布的 GNU 通用公共许可证修改之，无论是版本 3 许可证，还是任何以后版都可以。
发布该程序是希望它能有用，但是并无保障;甚至连可销售和符合某个特定的目的都不保证。请参看 GNU 通用公共许可证，了解详情。
你应该随程序获得一份 GNU 通用公共许可证的复本。如果没有，请看 <https://www.gnu.org/licenses/>。
"""))),
      ExpansionPanel(
        isExpanded: _expandState[4],
        headerBuilder: ((context, isExpanded) {
          return const ListTile(title: Text("支持作者"));
        }), body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(8), child: Text("""
这个软件预计会有一些广告
分为横幅广告和视频广告
横幅广告在终端和控制页面的顶端出现
(但不知道是不是因为代码没写对
反正我从没见横幅广告成功加载过)
视频广告在需要解锁某些功能时自行观看

这些功能需要累计完整观看对应数目广告后永久解锁：
启用终端: 观看2个广告
启用小键盘: 观看3个广告
关闭横幅广告: 观看5个广告
终端最大行数修改: 观看6个广告
推流参数修改: 观看8个广告
启用virgl加速: 观看10个广告
HiDPI环境变量修改: 观看12个广告

我设置了每天最多可以看5个广告。
只要看满1个广告, 就可以在本次使用期间临时解锁全部功能。
只要看满2个广告, 就可以在当日使用期间临时解锁全部功能。

总之为了良好的体验
在图形界面是不会出现广告的
这点还请放心

---注意事项---

我注意到Unity提供了一些不那么合适的广告
一般如果我看到这些广告就在后台直接禁了
不过也可能有漏网之鱼
可以联系我禁掉
""")),
          ElevatedButton(
            onPressed: () {
              launchUrl(Uri.parse("https://github.com/Cateners/tiny_computer"), mode: LaunchMode.externalApplication);
            },
            child: const Text("项目地址"),
          ),
        ]
      )),
    ],
  );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: FractionallySizedBox(
              widthFactor: 0.4,
              child: FlutterLogo()
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: ValueListenableBuilder(valueListenable: G.updateText, builder:(context, value, child) {
              return Text(value, textScaler: const TextScaler.linear(2));
            }),
          ),
          const FakeLoadingStatus(),
          const Expanded(child: Padding(padding: EdgeInsets.all(8), child: Card(child: Padding(padding: EdgeInsets.all(8), child: 
            Scrollbar(child:
              SingleChildScrollView(
                child: InfoPage(openFirstInfo: true)
              )
            )
          ))
          ,))
        ]
      )
    );
  }
}

class ForceScaleGestureRecognizer extends ScaleGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    super.acceptGesture(pointer);
  }
}

RawGestureDetector forceScaleGestureDetector({
  GestureScaleUpdateCallback? onScaleUpdate,
  GestureScaleEndCallback? onScaleEnd,
  Widget? child,
}) {
  return RawGestureDetector(
    gestures: {
      ForceScaleGestureRecognizer:GestureRecognizerFactoryWithHandlers<ForceScaleGestureRecognizer>(() {
        return ForceScaleGestureRecognizer();
      }, (detector) {
        detector.onUpdate = onScaleUpdate;
        detector.onEnd = onScaleEnd;
      })
    },
    child: child,
  );
}

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: forceScaleGestureDetector(onScaleUpdate: (details) {
        G.termFontScale.value = (details.scale * (Util.getGlobal("termFontScale") as double)).clamp(0.2, 5);
      }, onScaleEnd: (details) async {
        await G.prefs.setDouble("termFontScale", G.termFontScale.value);
      }, child: ValueListenableBuilder(valueListenable: G.termFontScale, builder:(context, value, child) {
        return TerminalView(G.termPtys[G.currentContainer]!.terminal, textScaleFactor: G.termFontScale.value, keyboardType: TextInputType.multiline);
      },) )), 
      ValueListenableBuilder(valueListenable: G.terminalPageChange, builder:(context, value, child) {
      return (Util.getGlobal("isTerminalCommandsEnabled") as bool)?Padding(padding: const EdgeInsets.all(8), child: Row(children: [AnimatedBuilder(
          animation: G.keyboard,
          builder: (context, child) => ToggleButtons(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            isSelected: [G.keyboard.ctrl, G.keyboard.alt, G.keyboard.shift],
            onPressed: (index) {
              switch (index) {
                case 0:
                  G.keyboard.ctrl = !G.keyboard.ctrl;
                  break;
                case 1:
                  G.keyboard.alt = !G.keyboard.alt;
                  break;
                case 2:
                  G.keyboard.shift = !G.keyboard.shift;
                  break;
              }
            },
            children: const [Text('Ctrl'), Text('Alt'), Text('Shift')],
          ),
        ),
        SizedBox.fromSize(size: const Size.square(8)), 
        Expanded(child: SizedBox(height: 24, child: ListView.separated(scrollDirection: Axis.horizontal, itemBuilder:(context, index) {
          return OutlinedButton(style: D.controlButtonStyle, onPressed: () {
            G.termPtys[G.currentContainer]!.terminal.keyInput(D.termCommands[index]["key"]! as TerminalKey);
          }, child: Text(D.termCommands[index]["name"]! as String));
        }, separatorBuilder:(context, index) {
          return SizedBox.fromSize(size: const Size.square(4));
        }, itemCount: D.termCommands.length))), SizedBox.fromSize(size: const Size(72, 0))])):SizedBox.fromSize(size: const Size.square(0));
      })
    ]);
  }
}

class FastCommands extends StatefulWidget {
  const FastCommands({super.key});

  @override
  State<FastCommands> createState() => _FastCommandsState();
}

class _FastCommandsState extends State<FastCommands> {

  @override
  Widget build(BuildContext context) {
    return Wrap(alignment: WrapAlignment.center, spacing: 4.0, runSpacing: 4.0, children: Util.getCurrentProp("commands")
      .asMap().entries.map<Widget>((e) {
      return OutlinedButton(style: D.commandButtonStyle, child: Text(e.value["name"]!), onPressed: () {
        Util.termWrite(e.value["command"]!);
        G.pageIndex.value = 0;
      }, onLongPress: () {
        String name = e.value["name"]!;
        String command = e.value["command"]!;
        showDialog(context: context, builder: (context) {
          return AlertDialog(title: const Text("指令编辑"), content: SingleChildScrollView(child: Column(children: [
            TextFormField(initialValue: name, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "指令名称"), onChanged: (value) {
              name = value;
            }),
            SizedBox.fromSize(size: const Size.square(8)),
            TextFormField(maxLines: null, initialValue: command, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "指令内容"), onChanged: (value) {
              command = value;
            }),
          ])), actions: [
            TextButton(onPressed:() async {
              await Util.setCurrentProp("commands", Util.getCurrentProp("commands")
                ..removeAt(e.key));
              setState(() {});
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }, child: const Text("删除该项")),
            TextButton(onPressed:() {
              Navigator.of(context).pop();
            }, child: const Text("取消")),
            TextButton(onPressed:() async {
              await Util.setCurrentProp("commands", Util.getCurrentProp("commands")
                ..setAll(e.key, [{"name": name, "command": command}]));
              setState(() {});
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }, child: const Text("保存")),
          ]);
        },);
      },);
    }).toList()..add(OutlinedButton(style: D.commandButtonStyle, onPressed:() {
        String name = "";
        String command = "";
        showDialog(context: context, builder: (context) {
          return AlertDialog(title: const Text("指令编辑"), content: SingleChildScrollView(child: Column(children: [
            TextFormField(initialValue: name, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "指令名称"), onChanged: (value) {
              name = value;
            }),
            SizedBox.fromSize(size: const Size.square(8)),
            TextFormField(maxLines: null, initialValue: command, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "指令内容"), onChanged: (value) {
              command = value;
            }),
          ])), actions: [
            TextButton(onPressed:() {
              Navigator.of(context).pop();
            }, child: const Text("取消")),
            TextButton(onPressed:() async {
              await Util.setCurrentProp("commands", Util.getCurrentProp("commands")
                ..add({"name": name, "command": command}));
              setState(() {});
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }, child: const Text("添加")),
          ]);
        },);
    }, onLongPress: () {
      showDialog(context: context, builder: (context) {
        return AlertDialog(title: const Text("重置指令"), content: const Text("是否重置所有快捷指令？"), actions: [
          TextButton(onPressed:() {
            Navigator.of(context).pop();
          }, child: const Text("取消")),
          TextButton(onPressed:() async {
            await Util.setCurrentProp("commands", D.commands);
            setState(() {});
            if (!context.mounted) return;
            Navigator.of(context).pop();
          }, child: const Text("是")),
        ]);
      });
    }, child: const Text("添加快捷指令"))));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool bannerAdsFailedToLoad = false;

  //安装完成了吗？
  //完成后从加载界面切换到主界面
  bool isLoadingComplete = false;

  @override
  Widget build(BuildContext context) {

    G.homePageStateContext = context;

    if (!isLoadingComplete) {
      Workflow.workflow().then((value) {
        setState(() {
          isLoadingComplete = true;
        });
      });
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(isLoadingComplete?Util.getCurrentProp("name"):widget.title),
      ),
      body: isLoadingComplete?Column(mainAxisSize: MainAxisSize.min, children: [
        ValueListenableBuilder(valueListenable: G.bannerAdsChange, builder:(context, value, child) {
          return (Util.getGlobal("isBannerAdsClosed") as bool)||bannerAdsFailedToLoad?SizedBox.fromSize(size: const Size.square(0)):UnityBannerAd(
            placementId: AdManager.bannerAdPlacementId,
            onLoad: (placementId) => debugPrint('Banner loaded: $placementId'),
            onClick: (placementId) => debugPrint('Banner clicked: $placementId'),
            onFailed: (placementId, error, message) {
              debugPrint('Banner Ad $placementId failed: $error $message');
              setState(() {
                bannerAdsFailedToLoad = true;
              });
            },
          );
        }), Expanded(child: ValueListenableBuilder(valueListenable: G.pageIndex, builder: (context, value, child) {
          return IndexedStack(index: G.pageIndex.value, children: [const TerminalPage(), Padding(
              padding: const EdgeInsets.all(8),
              child: Scrollbar(child: SingleChildScrollView(restorationId: "control-scroll", child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: FractionallySizedBox(
                      widthFactor: 0.4,
                      child: Image(
                        image: AssetImage("images/icon.png")
                      )
                    ),
                  ),
                  /*Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Text(Util.getCurrentProp("name"), textScaleFactor: 2),
                  ),*/
                  const FastCommands(),
                  Padding(padding: const EdgeInsets.all(8), child: Card(child: Padding(padding: const EdgeInsets.all(8), child: 
                    Column(children: [
                      const SettingPage(),
                      SizedBox.fromSize(size: const Size.square(8)),
                      const InfoPage(openFirstInfo: false)
                    ])
                  )))
                ]
              )))
          )]);
        }))]):const LoadingPage(),
      bottomNavigationBar: ValueListenableBuilder(valueListenable: G.pageIndex, builder:(context, value, child) {
        return Visibility(visible: isLoadingComplete,
          // child: BottomNavigationBar(currentIndex: G.pageIndex.value,
          //   onTap: (index) {
          //     G.pageIndex.value = index;
          //   },
          //   items: const [
          //     BottomNavigationBarItem(icon: Icon(Icons.monitor), label: "终端"),
          //     BottomNavigationBarItem(icon: Icon(Icons.video_settings), label: "控制"),
          //   ],
          // )
          child: NavigationBar(
            selectedIndex: G.pageIndex.value,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.monitor), label: "终端"),
              NavigationDestination(icon: Icon(Icons.video_settings), label: "控制")
            ],
            onDestinationSelected: (index) {
              G.pageIndex.value = index;
            },
          ),
        );}),
      floatingActionButton: ValueListenableBuilder(valueListenable: G.pageIndex, builder:(context, value, child) {
        return Visibility(visible: isLoadingComplete && (value == 0),
          child: FloatingActionButton(
            onPressed: () => Workflow.launchBrowser(),
            tooltip: "进入图形界面",
            child: const Icon(Icons.play_arrow),
          ),
        );
      }), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
