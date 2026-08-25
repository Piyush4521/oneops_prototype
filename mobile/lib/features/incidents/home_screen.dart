import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/api.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  Map<String,dynamic>? state; bool busy=false; String status='Ready'; final picker=ImagePicker(); final speech=stt.SpeechToText(); String voice='';
  @override void initState(){super.initState(); refresh();}
  Future<void> refresh() async { try { final s=await OneOpsApi.getState(); if(mounted)setState(()=>state=s); } catch(e){ if(mounted)setState(()=>status='Backend unavailable'); } }
  Future<void> run(Future<Map<String,dynamic>> Function() f, String label) async { setState(()=>busy=true); try { final s=await f(); setState(()=>state=s); } catch(e){ setState(()=>status=e.toString()); } finally { if(mounted)setState(()=>busy=false); } }
  Future<void> camera() async { final x=await picker.pickImage(source: ImageSource.camera, imageQuality:70); if(x==null)return; setState(()=>status='Reading captured evidence…'); final b=base64Encode(await File(x.path).readAsBytes()); try { final s=await OneOpsApi.capture(note:'Camera evidence captured from phone',imageBase64:b); setState(()=>state=s); } catch(e){setState(()=>status=e.toString());} }
  Future<void> voiceInput() async { if(await speech.initialize()){ setState(()=>voice='Listening…'); await speech.listen(onResult:(r){setState(()=>voice=r.recognizedWords);}); } }
  Color stateColor(String s)=>s.contains('VERIFIED')?const Color(0xFF41D38B):s.contains('FAIL')?const Color(0xFFFF6B6B):const Color(0xFF4DA3FF);
  @override Widget build(BuildContext c){ final i=state?['incident'] as Map<String,dynamic>?; final steps=(state?['steps'] as List?)?.cast<Map<String,dynamic>>()??[]; return Scaffold(
    appBar: AppBar(title: const Text('OneOps',style:TextStyle(fontWeight:FontWeight.w700)), actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body: RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[Container(width:9,height:9,decoration:BoxDecoration(color:stateColor(i?['status']??'READY'),shape:BoxShape.circle)),const SizedBox(width:8),Text(i?['status']??'READY',style:const TextStyle(fontWeight:FontWeight.w700)),const Spacer(),Text(i?['id']??'NO INCIDENT',style:TextStyle(color:Colors.grey[500]))]),
      const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Incident Capsule',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:12),Text(i?['summary']??'No active incident.'),const SizedBox(height:12),Row(children:[_metric('Severity',i?['severity']??'—'),_metric('Confidence','${i?['confidence']??0}%'),_metric('MTTR',i?['mttr']??'—')])]))),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Evidence',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:8),...((i?['evidence'] as List?)??[]).map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.check_circle_outline,size:17,color:Color(0xFF41D38B)),const SizedBox(width:8),Expanded(child:Text(e.toString()))]))) ]))),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Investigation',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(i?['hypothesis']??'No hypothesis yet.'),const SizedBox(height:10),Text(i?['experiment']??'No experiment selected.',style:TextStyle(color:Colors.grey[400]))]))),
      const SizedBox(height:12),
      if(voice.isNotEmpty) Card(child:Padding(padding:const EdgeInsets.all(12),child:Text('Voice: $voice'))),
      ...steps.map((s)=>ListTile(contentPadding:EdgeInsets.zero,leading:Icon(s['done']==true?Icons.check_circle:Icons.radio_button_unchecked,color:s['done']==true?const Color(0xFF41D38B):Colors.grey),title:Text(s['label']),subtitle:Text(s['detail']??''))),
      const SizedBox(height:8),
      Wrap(spacing:8,runSpacing:8,children:[
        FilledButton.icon(onPressed:busy?null:()=>run(OneOpsApi.injectFailure,'Injecting'),icon:const Icon(Icons.bug_report),label:const Text('Inject failure')),
        OutlinedButton.icon(onPressed:busy?null:camera,icon:const Icon(Icons.camera_alt),label:const Text('Capture')),
        OutlinedButton.icon(onPressed:busy?null:voiceInput,icon:const Icon(Icons.mic),label:const Text('Voice')),
        OutlinedButton.icon(onPressed:busy?null:()=>run(OneOpsApi.investigate,'Investigating'),icon:const Icon(Icons.search),label:const Text('Investigate')),
        OutlinedButton.icon(onPressed:busy?null:()=>run(OneOpsApi.reproduce,'Reproducing'),icon:const Icon(Icons.science),label:const Text('Reproduce')),
        OutlinedButton.icon(onPressed:busy?null:()=>run(OneOpsApi.verifyFix,'Verifying'),icon:const Icon(Icons.verified),label:const Text('Verify fix')),
        FilledButton.icon(onPressed:busy?null:()=>run(OneOpsApi.approveAndRecover,'Recovering'),icon:const Icon(Icons.lock_open),label:const Text('Approve & recover')),
      ]),
      if(busy) const Padding(padding:EdgeInsets.only(top:16),child:LinearProgressIndicator()),
      if(status!='Ready') Padding(padding:const EdgeInsets.only(top:12),child:Text(status,style:TextStyle(color:Colors.orange[300])))
    ])))); }
  Widget _metric(String a,String b)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:TextStyle(color:Colors.grey[500],fontSize:12)),const SizedBox(height:2),Text(b,style:const TextStyle(fontWeight:FontWeight.w700))]));
}
