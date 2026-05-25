import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

public class TestF10Request {
    public static void main(String[] args) {
        int market = 0;
        String code = "000001";
        
        // Build request payload
        ByteBuffer payload = ByteBuffer.allocate(24);
        
        // 固定头部 (12字节)
        byte[] header = new byte[] {0x0c, 0x0f, 0x10, (byte)0x9b, 0x00, 0x01, 0x0e, 0x00, 0x0e, 0x00, (byte)0xcf, 0x02};
        payload.put(header);
        
        // 参数部分
        payload.putShort((short) market);
        
        // 股票代码
        byte[] bytes = code.getBytes(StandardCharsets.US_ASCII);
        byte[] padded = new byte[6];
        System.arraycopy(bytes, 0, padded, 0, Math.min(bytes.length, 6));
        payload.put(padded);
        
        payload.putInt(0); // 4字节0
        
        // 打印结果
        byte[] result = payload.array();
        StringBuilder hex = new StringBuilder();
        for (byte b : result) {
            hex.append(String.format("%02x", b));
        }
        
        System.out.println("Java package: " + hex.toString());
        System.out.println("Python pkg:   0c0f109b00010e000e00cf02000030303030303100000000");
        System.out.println("Match: " + hex.toString().equals("0c0f109b00010e000e00cf02000030303030303100000000"));
    }
}
