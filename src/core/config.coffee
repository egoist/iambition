module.exports = 
  site: 
    name: 'iambition'
    slogan: '让世界见识你的想象力'
    description: '把你的奇思妙想转化为下一个改变世界的产品'

  port: process.env.PORT
  session:
    name: 'iambition::sess'
    key: process.env.IAM_SESSION_KEY