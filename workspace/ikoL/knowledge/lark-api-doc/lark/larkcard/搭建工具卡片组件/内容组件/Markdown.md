# Markdown

消息卡片提供 Markdown 组件，支持渲染文本、图片、分割线等元素。本文将介绍 Markdown 组件以及对应的 JSON 参数说明。
**注意事项**：本文档为旧版消息卡片文档。查看新版Lark卡片文档，参考[富文本（Markdown）](https://open.larksuite.com/document/uAjLw4CM/ukzMukzMukzM/feishu-cards/card-components/content-components/rich-text)。

## 组件展示

在消息卡片搭建工具内，Markdown 组件如下图所示。添加组件后，你可以调整 **样式**、**内容**、**交互** 等配置项。
**注意事项**：搭建工具暂不支持调试和预览有序列表、无序列表、代码块语法。
![image.png](//sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ea3ff0681b19daa234f78cc10574d23f_07OrA7bozh.png?height=1418&lazyload=true&maxWidth=600&width=2882)

此外，在工具提供的文本组件中，支持将文本格式调整为 Markdown。对应的 JSON 描述是在 `text` 元素中设置 `"tag": "lark_md"`，详情可参见[文本组件](https://open.larksuite.com/document/ukTMukTMukTM/uUzNwUjL1cDM14SN3ATN)。

![image.png](//sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/143fa6eb49b56c3b40be1d253f66406e_Xj4WhfywWW.png?height=1412&lazyload=true&maxWidth=600&width=2882)
- 在 text 元素中无法使用与文本格式无关的 markdown 标签（例如，图片、分割线）。
- 本文仅介绍卡片的 Markdown 内容格式，在实际发送卡片消息时，你需要结合具体接口的参数配置使用。例如，调用[发送消息](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/message/create)接口时，Markdown 卡片内容需要传入接口的 `content` 字段，此外还需要根据卡片内容设置消息类型（`msg_type`）、消息接收者 ID（`receive_id`）等字段。

## 参数说明

Markdown 组件包含的参数说明如下表所示。

参数 | 是否必须 | 类型 | 说明
---|---|---|---
tag | 是 | String | Markdown 组件的标识。固定取值：markdown
content | 是 | String | 使用已支持的 Markdown 语法构造 Markdown 内容。语法详情可参见下文 **支持的语法** 章节。
text_align | 否 | String | 设置文本内容的对齐方式。取值：<br>* **left**：左对齐<br>* **center**：居中对齐<br>* **right**：右对齐<br>**默认值**：left
href | 否 | Object | 差异化跳转。仅在 PC 端、移动端需要跳转不同链接时使用。<br>示例值：<br>```<br>{<br>"urlVal": {<br>"url": "https://feishu.com",<br>"android_url": "https://android.com/",<br>"ios_url": "https://apple.com/",<br>"pc_url": "https://windows.com"<br>}<br>}<br>```

## 支持的语法

目前只支持 markdown 语法的子集，详情参见下表。

名称 | 语法 | 效果 | 可用范围
---|---|---|---
换行 | ```<br>\n<br>``` | 文本<br>换行 | * Markdown 组件<br>* text 元素
斜体 | ```<br>*斜体*<br>``` | *斜体* | * Markdown 组件<br>* text 元素
加粗 | ```<br>**粗体**<br>或<br>__粗体__<br>``` | __粗体__ | * Markdown 组件<br>* text 元素
删除线 | ```<br>~~删除线~~<br>``` | ~~删除线~~ | * Markdown 组件<br>* text 元素
@指定人 | ```<br><at id=open_id></at><br><at id=user_id></at><br><at email=test@email.com></at><br>``` | @用户名 | * Markdown 组件<br>* text 元素<br>**注意事项**：[自定义机器人](https://open.larksuite.com/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN)仅支持使用 `open_id`、`user_id` @指定人。
@所有人 | ```<br><at id=all></at><br>``` | @所有人 | * Markdown 组件<br>* text 元素<br>**注意事项**：@所有人需要群主开启权限。若未开启，卡片将发送失败。
超链接 | ```<br><a href='https://open.larksuite.com'><br></a><br>``` | [https://open.larksuite.com](https://open.larksuite.com) | * Markdown 组件<br>* text 元素<br>**注意事项**：超链接必须包含 schema 才能生效，目前仅支持 HTTP 和 HTTPS。
彩色文本样式 | ```<br>这是一个绿色文本 <br>这是一个红色文本<br>这是一个灰色文本<br>``` | ![](https://sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ark/670a7df35913641821d7468c25e98159.png?height=46&lazyload=true&width=206)<br>![](https://sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ark/dbb23d9613708110c8a33bda5d5129c9.png?height=46&lazyload=true&width=200)<br>![](https://sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ark/9095f4cda3ae8e8574341d5d6156f0c7.png?height=40&lazyload=true&width=192) | * Markdown 组件<br>* text 元素<br>* 彩色文本样式不支持对链接、文本生效<br>**注意事项**：支持红、灰、绿三种彩色文本。color 取值：<br>* **green**：绿色文本<br>* **red**：红色文本<br>* **grey**：灰色文本<br>* **default**：默认的白底黑字样式
文字链接 | ```<br>[开放平台](https://open.larksuite.com/)<br>``` | [开放平台](https://open.larksuite.com/) | * Markdown 组件<br>* text 元素<br>**注意事项**：超链接必须包含 schema 才能生效，目前仅支持 HTTP 和 HTTPS。
差异化跳转 | ```<br>{<br>"tag": "markdown",<br>"href": {<br>"urlVal": {<br>"url": "xxx",<br>"pc_url":"xxx",<br>"ios_url": "xxx",<br>"android_url": "xxx"<br>}<br>},<br>"content":<br>"[差异化跳转]($urlVal)"<br>}<br>``` | \- | * Markdown 组件<br>* text 元素<br>* 超链接必须包含 schema 才能生效，目前仅支持 HTTP 和 HTTPS。<br>**注意事项**：仅在 PC 端、移动端需要跳转不同链接时使用。
图片 | ```<br>![hover_text](image_key)<br>``` | ![图片](https://sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ark/164d7d1d03bbff05ed1fb27766baa26f.png?height=582&lazyload=true&width=582) | * 仅支持 Markdown 组件<br>* 不支持在 text 元素的 `lark_md` 类型中使用<br>**注意事项**：* 提示文案是指，在 PC 端内光标悬浮（hover）图片所展示的文案。<br>* **image_key** 可以调用[上传图片](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/image/create)接口获取。
分割线 | ```<br>\n ---\n<br>``` | ![](https://sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ark/9031fafb4c84c7fec5ddcaebad5255b4.png?height=62&lazyload=true&width=346) | * 仅支持 Markdown 组件<br>* 不支持在 text 元素的 `lark_md` 类型中使用<br>**注意事项**：`---` 符号必须跟在换行符后使用，且与换行符之间有 1 个空格。
Lark表情 | ```<br>:Emoji Key:<br>``` | ![](https://sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/ark/5462582d55eaec662cd13225408f4a7c.png?height=96&lazyload=true&width=96) | * Markdown 组件<br>* text 元素<br>* 支持的 Emoji Key 列表可以参看 [表情文案说明](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/message-reaction/emojis-introduce)
标签 | ```<br><text_tag color='red'>标签文本</text_tag><br>``` | ![image.png](//sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/4105178f31cc40ef499feae123754098_W9hZbwm3fv.png?height=646&lazyload=true&width=188) | * Markdown 组件<br>* text 元素<br>* `color`支持的枚举值范围包括：`neutral` `blue` `turquoise` `lime` `orange` `violet` `indigo` `wathet` `green` `yellow` `red` `purple` `carmine`<br>**注意事项**：消息卡片搭建工具不支持调试和预览该语法。你可使用新版[Lark卡片搭建工具](https://open.larksuite.com/cardkit)调试或预览，或通过点击工具右上角的“向我发送预览”在Lark客户端中预览效果。
有序列表 | ```<br>1. 有序列表1<br>1. 有序列表 1.1<br>2. 有序列表2<br>``` | 1. 有序列表1<br>1. 有序列表 1.1<br>2. 有序列表2 | * 仅支持 Markdown 组件<br>* 序号需在行首使用<br>* 4 个空格代表一层缩进<br>**注意事项**：仅在Lark 7.6 及以上版本生效。在低版本Lark客户端中，包含该语法的 Markdown 组件将展示为升级提示占位图。
无序列表 | ```<br>- 无序列表1<br>- 无序列表 1.1<br>- 无序列表2<br>``` | - 无序列表1<br>- 无序列表 1.1<br>- 无序列表2 | * 仅支持 Markdown 组件<br>* 序号需在行首使用<br>* 4 个空格代表一层缩进<br>**注意事项**：仅在Lark 7.6 及以上版本生效。在低版本Lark客户端中，包含该语法的 Markdown 组件将展示为升级提示占位图。
代码块 | `````markdown<br>```JSON<br>{"This is": "JSON demo"}<br>```<br>````` | ```JSON<br>{"This is": "JSON demo"}<br>``` | * 仅支持 Markdown 组件<br>* 代码块语法和代码内容需在行首使用<br>* 支持指定编程语言解析。未指定默认为 Plain Text<br>**注意事项**：仅在Lark 7.6 及以上版本生效。在低版本Lark客户端中，包含该语法的 Markdown 组件将展示为升级提示占位图。

如果你要展示的字符命中了 markdown 语法使用的特殊字符（例如 `*、~、>、<` 这些特殊符号），需要对特殊字符进行 HTML 转义，才可正常展示。常见的转义符号对照表如下所示。查看更多转义符，参考 [HTML 转义通用标准](https://www.w3school.com.cn/charsets/ref_html_8859.asp)实现，转义后的格式为 `&#实体编号;`。

| **特殊字符** | **转义符** | **描述** |
| --- | --- | --- |
| ` ` | `&nbsp;	` | 不换行空格 |
| ` ` | `&ensp;` | 半角空格 |
| `  ` | `&emsp;` | 全角空格 |
| `>` | `&#62;` | 大于号 |
| `<` | `&#60;` | 小于号 |
| `~` | `&sim;` | 飘号 |
| `-` | `&#45;` | 连字符 |
| `!` | `&#33;` | 惊叹号 |
| `*` | `&#42;` | 星号 |
| `/` | `&#47;` | 斜杠 |
| `\` | `&#92;` | 反斜杠 |
| `[` | `&#91;` | 中括号左边部分 |
| `]` | `&#93;` | 中括号右边部分 |
| `(` | `&#40;` | 小括号左边部分 |
| `)` | `&#41;` | 小括号右边部分 |
| `#` | `&#35;` | 井号 |
| `:` | `&#58;` | 冒号 |
| `+` | `&#43;` | 加号 |
| `"` | `&#34;` | 英文引号 |
| `'` | `&#39;` | 英文单引号 |
| \`  | `&#96;` | 反单引号 |
| `$` | `&#36;` | 美金符号 |
| `_` | `&#95;` | 下划线 |
| `-` | `&#45;` | 无序列表 |

## 卡片示例

### Markdown 组件

在消息卡片 Markdown 组件中的使用示例，如下 JSON 代码所示。

```json
{
  "elements": [
    {
      "tag": "markdown",
      "href": {
        "urlVal": {
          "url": "xxx1",
          "pc_url": "xxx2",
          "ios_url": "xxx3",
          "android_url": "xxx4"
        }
      },
      "content": "普通文本\n标准emoji😁😢🌞💼🏆❌✅\n*斜体*\n**粗体**\n~~删除线~~\n[文字链接](www.example.com)\n[差异化跳转]($urlVal)\n<at id=all></at>"
    },
    {
      "tag": "hr"
    },
    {
      "tag": "markdown",
      "content": "上面是一行分割线\n![hover_text](img_v2_16d4ea4f-6cd5-48fa-97fd-25c8d4e79b0g)\n上面是一个图片标签"
    }
  ],
  "header": {
    "template": "blue",
    "title": {
      "content": "这是卡片标题栏",
      "tag": "plain_text"
    }
  }
}
```

实现效果如下图所示：

![](//sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/2ff57071d208164ce6a97aefaf91273c_2EvqmBCyAB.png?height=1148&lazyload=true&maxWidth=400&width=772)

### text 的 lark_md 模式

将[文本组件](https://open.larksuite.com/document/ukTMukTMukTM/uUzNwUjL1cDM14SN3ATN)的 `tag` 字段声明为 `lark_md`，可以使用 Markdown 标签配置 `text` 中的文本格式。使用示例如下 JSON 代码。

```json
{
  "elements": [
    {
      "tag": "div",
      "text": {
        "tag": "plain_text",
        "content": "text-lark_md",
        "lines": 1
      },
      "fields": [
        {
          "is_short": false,
          "text": {
            "tag": "lark_md",
            "content": "<a>https://open.larksuite.com</a>"
          }
        },
        {
          "is_short": false,
          "text": {
            "tag": "lark_md",
            "content": "ready\nnew line"
          }
        },
        {
          "is_short": false,
          "text": {
            "tag": "lark_md",
            "content": "*Italic*"
          }
        },
        {
          "is_short": false,
          "text": {
            "tag": "lark_md",
            "content": "**Bold**"
          }
        },
        {
          "is_short": false,
          "text": {
            "tag": "lark_md",
            "content": "~~delete line~~"
          }
        },
        {
          "is_short": false,
          "text": {
            "tag": "lark_md",
            "content": "<at id=all></at>"
          }
        }
      ]
    }
  ]
}
```

实现效果如下图所示：

![](//sf16-sg.larksuitecdn.com/obj/open-platform-opendoc-sg/24de2acf3d2df6b0d9adfc1b62b199e8_QnuV2LvpKV.png?height=400&lazyload=true&maxWidth=400&width=798)
