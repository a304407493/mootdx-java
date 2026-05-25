import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

public class TestPayload {
    public static void main(String[] args) {
        int market = 0;
        String cleanCode = "000001";
        String filename = "000001.txt";
        
        // Build request payload
        ByteBuffer payload = ByteBuffer.allocate(114);

        // Fixed header (12 bytes)
        byte[] header = new byte[] {0x0c, 0x07, 0x10, (byte)0x9c, 0x00, 0x01, 0x68, 0x00, 0x68, 0x00, (byte)0xd0, 0x02};
        payload.put(header);

        // Parameters
        payload.putShort((short) market);

        // Stock code
        byte[] codeBytes = new byte[6];
        byte[] inputCode = cleanCode.getBytes(StandardCharsets.US_ASCII);
        System.arraycopy(inputCode, 0, codeBytes, 0, Math.min(inputCode.length, 6));
        payload.put(codeBytes);

        payload.putShort((short) 0); // 2 bytes zero

        // Filename
        byte[] filenameBytes = new byte[80];
        byte[] inputFilename = filename.getBytes(StandardCharsets.US_ASCII);
        System.arraycopy(inputFilename, 0, filenameBytes, 0, Math.min(inputFilename.length, 80));
        payload.put(filenameBytes);

        payload.putInt(0); // start
        payload.putInt(10000); // length
        payload.putInt(0); // zero

        System.out.println("Payload position: " + payload.position());
        
        byte[] result = payload.array();
        System.out.println("Payload array length: " + result.length);
        
        StringBuilder hex = new StringBuilder();
        for (int i = 0; i < Math.min(result.length, 40); i++) {
            hex.append(String.format("%02X ", result[i]));
        }
        System.out.println("First 40 bytes: " + hex.toString());
    }
}
