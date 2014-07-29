Natural-Language-Generation
===========================
Run ```coffee app.coffee```


Description:
------------
โปรแกรมแบ่งเป็น 2 ส่วนคือ

1. Data Preparation: เตรียมข้อมูลที่จำเป็นสำหรับการสร้างประโยค
2. Sentence Generation: นำ data จากข้อหนึ่งมาเขียนเป็นประโยค

### Data Preparation
เตรียมข้อมูลที่จำเป็นต้องใช้ในการแต่งประโยค
object เริ่มต้นเป็น input ที่มีลักษณะดังนี้

#### ไม่มีข้อมูลเปรียบเทียบ
```
{
	"data": [
		{
			"title": "Jitta Line",
			"newData": "62.62% Below Jitta Line",
			"alwaysShow": true
		},
		...
	]
}
```
#### มีข้อมูลเปรียบเทียบ
```
{
	"data": [
		{
			"title": "Jitta Line",
			"oldData": "52.62% Below Jitta Line",
			"newData": "62.62% Below Jitta Line",
			"alwaysShow": true
		},
		...
	]
}
```
1. ประเภทของข้อมูล (dataType) ดึงมาจาก config.json
2. ประเภทของประโยค (sentenceType) ดึงมาจาก config.json สำหรับเลือกรูปแบบประโยคที่ใช้แต่ง
3. ประเภทของเนื้อหา (contentGroup) ดึงมาจาก config.json สำหรับรวมกลุ่มประโยคที่มีเนื้อหาคล้ายกัน
4. คำนวณความแตกต่างของข้อมูลเก่าและข้อมูลใหม่ (difference)
 - มี built-in ฟังก์ชัน getDifference สำหรับข้อมูลที่เป็นตัวเลข
 - difference = 'na' ถ้าไม่มีข้อมูลให้เปรียบเทียบ
 - สามารถ override ฟังก์ชัน getDifference ได้ใน data_config.coffee
6. ลำดับความสำคัญ (priority) ให้ค่าความสำคัญของข้อมูลนั้น เลขมากจะมีค่าความสำคัญมาก ค่าความสำคัญจะแปรผันไปกับค่าความเปลี่ยนแปลง (difference ในข้อ 4)
 - ตั้งค่าที่ใช้ในการคำนวณความสำคัญได้ที่ config.json
  ```
"priority": {
	"init": 1,             // ค่า priority เริ่มต้น
	"negativeFactor": 20,  // อัตราเพิ่มเมื่อ difference เป็นลบ
	"positiveFactor": 100  // อัตราเพิ่มเมื่อ difference เป็นบวก
}
  ```
 - ถ้าไม่มีค่า difference แล้ว priority จะเท่ากับค่าตั้งต้น (init)
 - สูตรของการคำนวณ priority คือ priority = init + (positive/negativeFactor * abs(difference))
 - สามารถ override ฟังก์ชัน calculatePriority ได้ใน data_config.coffee
7. ค่าความรุนแรงของการเปลี่ยนแปลง (level) มีค่าระหว่าง -3 ถึง 3 (ศูนย์คือไม่มีความเปลี่ยนแปลง)
 - level = 0 คือไม่มีความเปลี่ยนแปลง
 - level มีค่าบวกถ้า difference เป็นบวก ค่า level มากแสดงว่ามีความรุนแรงของการเปลี่ยนแปลงมาก และ level มีค่าลบถ้า difference เป็นค่าลบ
 - level = 'na' ถ้าไม่มีข้อมูลให้เปรียบเทียบ
 - สามารถ override ฟังก์ชัน calculateLevel ได้ใน data_config.coffee
8. ประเภทของการเปลี่ยนแปลง (levelType) แบ่งประเภทของการเปลี่ยนแปลงหยาบๆ เป็น positive, negative, neutral หรือ na
9. ข้อมูลที่ใช้แสดงในประโยค (displayInfo) เป็น key-value object ของสตริงที่นำไปใส่ในประโยค
 - มี built-in ฟังก์ชัน getDisplayInfo สำหรับข้อมูลทั่วไป (ดึงตรงๆ มาจาก input เลย)
 - สามารถ override ฟังก์ชัน getDisplayInfo เพื่อเพิ่มสตริงหรือตัดแต่งสตริงได้

### Sentence Generation
นำข้อมูลจากขั้นตอนด้านบนมาสร้างเป็นประโยค

Sample output:
--------------

#### Short

The price has decreased from 53% to 62.62% below jitta line. Jitta score looks good at 7.0. The price has significantly decreased by 16% to 80 baht. CapEx is very low, and there is share repurchase every year.

#### Full

The price has decreased from 53% to 62.62% below jitta line. Jitta score is still good at 7.0. The price has extremely dropped to 80 baht. CapEx is very low, and there is share repurchase every year. Operating margin is declined, but dividend payout is increasing every year. There is return on equity, but earning loss detected in the past years. Return on equity is still consistently high. Growth opportunity has significantly decreased by 30 to 60, but competitive advantage has increased by 2 to 100. Recent business performance has raised from 35 to 50 and return to share holder is still good at 69. Financial strength is still good at 100.