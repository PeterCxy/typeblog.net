```json
{
  "title": "OpenJDK7编译Android4.4小记",
  "url": "build-android-kitkat-with-openjdk7",
  "date": "2014-07-10",
  "parser": "Markdown"
}
```


自从上次Oracle状告Google以后，Android官网上推荐的JDK就改成OpenJDK7了，但目前只有AOSP的master分支和l-preview分支及以后的版本才支持用OpenJDK7编译。本着“为未来做准备”的态度，我尝试用OpenJDK7编译了一次Android 4.4(KitKat)，当然遇到了很多问题。

<!--more-->

__libcore/libdvm & libcore/libart__  
报错位置: 对应目录下的 *src/main/java/java/lang/Enum.java*  
解决方法: 感谢 [秋叶随风](http://www.3rdos.com/)  
```java
     public final int compareTo(E o) {
 -        return ordinal - o.ordinal;
 +        return ordinal - o.ordinal ();
      }
```


__frameworks/opt/telephony__  
报错位置: *src/java/com/android/internal/telephony/gsm/GSMPhone.java*  
解决方法: 感谢 [秋叶随风](http://www.3rdos.com/)  
> 删除 public GSMPhone (Context context, CommandsInterface ci, PhoneNotifier notifier, boolean unitTestMode) 构造器中的 if (DBG_PORT) {}语句块即可


__packages/apps/Gallery2__  
报错位置: *src/com/android/gallery3d/util/LinkedNode.java*  
解决方法: 感谢 [秋叶随风](http://www.3rdos.com/)  
```java
 public class LinkedNode {
 -    private LinkedNode mPrev;
 -    private LinkedNode mNext;
 +    protected LinkedNode mPrev;
 +    protected LinkedNode mNext;
  
      public LinkedNode() {
          mPrev = mNext = this;
```


__build__  
报错位置: *各种makefile*  
解决方法: 修改太多，请见 <https://github.com/LOSP/android_build/commits/kk>  大体就是修改需求的java版本号来解决问题


__external/chromium_org__  
报错位置: (这个可能并不是所有人都会遇到)*base/android/jni_generator/jni_generator.py*  
解决方法:  
```java
   @staticmethod
    def CreateFromClass(class_file, options):
      class_name = os.path.splitext(os.path.basename(class_file))[0]
 -    p = subprocess.Popen(args=['javap', '-s', class_name],
 +    p = subprocess.Popen(args=['javap', '-s', class_file],
                           cwd=os.path.dirname(class_file),
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
```


__frameworks/base__  
报错位置1: *out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/src/android/telephony/gsm/SmsManager.java*  
(或) *out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/src/android/telephony/gsm/SmsMessage.java*  
解决方法1: *frameworks/base/Android.mk*  
```makefile
 	../../external/apache-http/src/org/apache/http \
  	../opt/telephony/src/java/android/provider \
  	../opt/telephony/src/java/android/telephony \
 -	../opt/telephony/src/java/android/telephony/gsm \
  	../opt/net/voip/src/java/android/net/rtp \
  	../opt/net/voip/src/java/android/net/sip
```

报错位置2: *packages/SystemUI/src/com/android/systemui/statusbar/SystemBars.java* (无参构造器缺失)  
解决方法2: (这个解决方法不完美，是个dirty fix)  
```java
 import com.android.systemui.R;
  import com.android.systemui.SystemUI;
 +import com.android.systemui.statusbar.phone.PhoneStatusBar;
  
  import java.io.FileDescriptor;
  import java.io.PrintWriter;
 @@ -97,7 +98,12 @@ private void createStatusBarFromConfig() {
              throw andLog("Error loading status bar component: " + clsName, t);
          }
          try {
 -            mStatusBar = (BaseStatusBar) cls.newInstance();
 +            if (clsName.contains("PhoneStatusBar")) {
 +                // Dirty fix "no zero argument constructor" error
 +                mStatusBar = new PhoneStatusBar();
 +            } else {
 +                mStatusBar = (BaseStatusBar) cls.newInstance();
 +            }
          } catch (Throwable t) {
              throw andLog("Error creating status bar component: " + clsName, t);
          }
 ```
 
 
 __external/proguard__  
 报错原因: 默认的proguard是4.4版本，不支持Java7  
 解决方法: revert commit *9f606f95f03a75961498803e24bee6799a7c0885* (此操作将升级proguard到4.7) (当然，会遇到冲突，你只要保留"====="后面的内容就可以了)
 
 
 以上就是我编译的时候遇到的所有错误，大家可以参考。当然，有些错误很奇葩，比如SystemBar那个错误，根本就不该发生。不管他了，反正我解决了。
