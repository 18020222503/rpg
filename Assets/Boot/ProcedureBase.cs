using UnityEngine;

public interface ProcedureBase
{
   void  OnInit();	 //状态机创建时调用一次
   void  OnEnter();	 //进入这个流程时调用
   void OnUpdate();	// 停在这个流程期间每帧调用
   void OnLeave();	 //离开这个流程时调用
   void OnDestroy(); //状态机销毁时调用
}
