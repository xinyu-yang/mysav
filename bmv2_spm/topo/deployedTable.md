# s1 table

## switchIngressAsn_exact / switchEgressAsn_exact
| switch port(bit<9>) | asn (bit<32>) |
|---------------------|---------------|
|         1           |         0     |
|          2          |         5     |

## ipv4Src2AS_lpm / ipv4Dst2AS_lpm

|prefix (bit<32>, int)| asn(bit<32>) | port (bit<9>) | dstAddr(bit<48>)| flags(bit<8>) |
|---------------|-------------|--------------|------------|-----------|
|11.11.1.1/32   |    0         | 1         |        08:00:00:11:11:11|0|
|22.22.0.0/16   |    2         | 2         |        08:00:00:00:05:01|1|
|33.33.0.0/16   |  3          |    2         | 08:00:00:00:05:01| 1 |
|44.44.0.0/16   |  4           | 2           |08:00:00:00:05:01 | 5  |
|55.55.0.0/16   |  5          |    2          |  08:00:00:00:05:01| 0 |
|66.66.0.0/16   |   6          |   2         |  08:00:00:00:05:01|4 |

## thisSrcPrefix_lpm / thisDstPrefix_lpm

|prefix (bit<32>, int)|
|------------------|
|11.11.0.0/16|

## AS2Key_exact 

|asn (bit<32>) | key (bit<4096>) |
|-------------|-----------------|
|       4       | [1]           |
|  6            |        [2]      |

## lastAS2Dst

|asn (bit<32>) | asn (bit<32>)|
|--------------|--------------|
|   2          |    0         |
|    3         |    6         |
|    5         |       0      |


# s4 table

## switchIngressAsn_exact / switchEgressAsn_exact
| switch port(bit<9>) | asn (bit<32>) |
|---------------------|---------------|
|         1           |         6     |
|          2          |         0     |

## ipv4Src2AS_lpm / ipv4Dst2AS_lpm

|prefix (bit<32>, int)| asn(bit<32>) | port (bit<9>) | dstAddr(bit<48>)| flags(bit<8>) |
|---------------|-------------|--------------|------------|-----------|
|22.22.0.0/16   |    2         | 1         |    08:00:00:00:06:03|1|
|33.33.0.0/16   |  3          |    1         | 08:00:00:00:06:03| 1 |
|11.11.0.0/16   |  1           | 1           |08:00:00:00:06:03 | 5 |
|44.44.1.1/32   |  0           | 2           |08:00:00:44:44:44 | 0  |
|55.55.0.0/16   |  5          |    1          |  08:00:00:00:06:03| 0 |
|66.66.0.0/16   |   6          |   1         |  08:00:00:00:06:03|4 |

## thisSrcPrefix_lpm / thisDstPrefix_lpm

|prefix (bit<32>, int)|
|------------------|
|44.44.0.0/16|

## AS2Key_exact 

|asn (bit<32>) | key (bit<4096>) |
|-------------|-----------------|
|       1       | [1]           |
|  6            |        [3]      |

## lastAS2Dst

|asn (bit<32>) | asn (bit<32>)|
|--------------|--------------|
|   2          |    6         |
|    3         |    6         |
|    5         |       6      |


# s6_1 table

## switchIngressAsn_exact / switchEgressAsn_exact
| switch port(bit<9>) | asn (bit<32>) |
|---------------------|---------------|
|         1           |         5     |
|          2          |         0     |
|          3          |         0     |

## ipv4Src2AS_lpm / ipv4Dst2AS_lpm

|prefix (bit<32>, int)| asn(bit<32>) | port (bit<9>) | dstAddr(bit<48>)| flags(bit<8>) |
|---------------|-------------|--------------|------------|-----------|
|22.22.0.0/16   |    2         | 1         |    08:00:00:00:05:02|2|
|33.33.0.0/16   |  3          |    2         | 08:00:00:00:06:02| 3 |
|11.11.0.0/16   |  1           | 1           |08:00:00:00:05:02 | 4 |
|55.55.0.0/16   |  5          |    1          |  08:00:00:00:05:02| 2 |
|44.44.0.0/16   |   4          |   3         |  08:00:00:00:06:03| 5 |

## thisSrcPrefix_lpm / thisDstPrefix_lpm

|prefix (bit<32>, int)|
|------------------|
|66.66.0.0/16|

## AS2Key_exact 

|asn (bit<32>) | key (bit<4096>) |
|-------------|-----------------|
|       1       | [2]           |
|  4            |        [3]    |

## lastAS2Dst

|asn (bit<32>) | asn (bit<32>)|
|--------------|--------------|
|   2          |    0         |
|    3         |    0         |
|    5         |       0      |


# s6_2 table

## switchIngressAsn_exact / switchEgressAsn_exact
| switch port(bit<9>) | asn (bit<32>) |
|---------------------|---------------|
|         1           |         0     |
|          2          |         3     |
|          3          |         0     |

## ipv4Src2AS_lpm / ipv4Dst2AS_lpm

|prefix (bit<32>, int)| asn(bit<32>) | port (bit<9>) | dstAddr(bit<48>)| flags(bit<8>) |
|---------------|-------------|--------------|------------|-----------|
|22.22.0.0/16   |    2         | 1         |    08:00:00:00:06:01| 2 |
|33.33.0.0/16   |  3          |    2         | 08:00:00:00:03:01| 3 |
|11.11.0.0/16   |  1           | 1           |08:00:00:00:06:01 | 4 |
|55.55.0.0/16   |  5          |    1          |  08:00:00:00:06:01| 2 |
|44.44.0.0/16   |   4          |   3         |  08:00:00:00:06:03| 5 |

## thisSrcPrefix_lpm / thisDstPrefix_lpm

|prefix (bit<32>, int)|
|------------------|
|66.66.0.0/16|

## AS2Key_exact 

|asn (bit<32>) | key (bit<4096>) |
|-------------|-----------------|
|       1       | [2]           |
|  4            |        [3]    |

## lastAS2Dst

|asn (bit<32>) | asn (bit<32>)|
|--------------|--------------|
|   2          |    0         |
|    3         |    0         |
|    5         |       0      |

# s6_3 table

## switchIngressAsn_exact / switchEgressAsn_exact
| switch port(bit<9>) | asn (bit<32>) |
|---------------------|---------------|
|         1           |         0     |
|          2          |         0     |
|          3          |         4     |

## ipv4Src2AS_lpm / ipv4Dst2AS_lpm

|prefix (bit<32>, int)| asn(bit<32>) | port (bit<9>) | dstAddr(bit<48>)| flags(bit<8>) |
|---------------|-------------|--------------|------------|-----------|
|22.22.0.0/16   |    2         | 1         |    08:00:00:00:06:01| 2 |
|33.33.0.0/16   |  3          |    2         | 08:00:00:00:06:02| 3 |
|11.11.0.0/16   |  1           | 1           |08:00:00:00:06:01 | 4 |
|55.55.0.0/16   |  5          |    1          |  08:00:00:00:06:01| 2 |
|44.44.0.0/16   |   4          |   3         |  08:00:00:00:04:01| 5 |

## thisSrcPrefix_lpm / thisDstPrefix_lpm

|prefix (bit<32>, int)|
|------------------|
|66.66.0.0/16|

## AS2Key_exact 

|asn (bit<32>) | key (bit<4096>) |
|-------------|-----------------|
|       1       | [2]           |
|  4            |        [3]    |

## lastAS2Dst

|asn (bit<32>) | asn (bit<32>)|
|--------------|--------------|
|   2          |    0         |
|    3         |    0         |
|    5         |       0      |


# Key
*[1] c645acc0b49df43a29da9d96ac22f1f68956072221e5e68f4ad85a8832bd178ebcaa1256d73cb70db08f35cd1c2b246945632e5c96db55c69752d6b766bf1ca9f84fbf5075c1a4283753566e56885492d8292be5c4638ed584f8b45f43aa07f24cf413d4c2a09c047e4ca44e53c4bcbefc7dfc66ebe0ce922cd3b6857042cf86b45372f8dba253a93716629c43cb62720bcee89975039caaa506a02f95d7f4e4089a18bd0429f3b8e06e9d5e15daf32b83493f7ef834eeed49783616dbf5e3adfd13df74d11961a5ae5dcfab56a9b03ace5ef6c307a42d27a59515a589c6f338ba24ac98d3435bb2f78513e33c95289b3150dfe38f15adfe918328151fcaf5fe560e6e2c16f439bf5d50f256b5fa77f99f47944b37fa18a6b128aeb9f83817258ab082ac6cfca7142920165478e7dbfbc5122cbcfdb29d0ff13d76745e81be5e945b93a300ef666604ba22a1f87a8e9156be851752742ce6b38f3188228bdd5777c454bdb55c29cd832c5a89a9577e7974867be487aa18643228ab8bc92d2e49467b4a1579c8c415eb99dd337b7afc0598f85938c2a82647ebb9b09cae97ed2577342f2e85b11be46420318f19522e900b1e65e54ebdea4226d1b20eda663cf57fa5d2385a57efd0f6f88710a85774033faa3da2db4cadb4d7d5ab5ff495e416f72f8dba66114f8dfc7d5e263c0d7ef7de064c7f98141e810b600d9caa79a0d3*

*[2] a86e4021161a28ef7669924f5a571e21c132e79fc3380610f5ae329981aed135c99f7d041875e611eb66cf93e937be08b0988fab82103d2079ba6b9e2c570a32434a2d4b750a90dd2c23a5d7561e7e9b7fc32153572587ec5d9f619d4f44c6e449d682bd93b969ffd42be34db64cb7fcaabbdffc86a05a0d3964c1b211a10586c6898f7a67ca471af8b309dcbc023566684a144c880aa52b6fcb18fb4e04ab3766a1c505839a16a3a135909f248d2478bdf76dce8eb3c6b1de35eaac122ad00c0c4d9fd0b13e7213123a062f048609df335e135b3cc389657daeb7b99cf2aa8c8e145b76cc87b54d6adac45c87473c2d1670600edba3552efea84029e4966bc9e6c0c5268e340cb6796fdfa1e855416e65058cfa122cb35c4c08e3a1313bbf75f0a351ad09eb353f4e11a9745f232a179661bc32034d190a707454e57647655ae5698cfe7115dda77741400e0776d2bce2d986274604e3c16464137ba37f4c41e40a57f5d531fc1d53dfd1acfc59453300206c506992be84c2c3944443e6360f411494ac308f979f04e63bc259b53efcc0e5a1794b6d39cdba92dca55b6406feb7debfc3159e4c3b4456360049a38092466ff4b55af17f64a7469bb7605f3e325621f99582a4993d0501e1abff4a6426279150ec1d27d098fbe6c9692858ba98964afaac785e13b31eff86e943396475b476c71d323b9c353096a7f70c34b805*

*[3] c9531f019c762426daf6e51d81131c5cc2cf00aa44ed0e676338aa46d29cf96153090cdf7e5211186d797be7bb4c9bcd97c22940831310ad449296b91fc1c1a2633574da53c60f15423b6361b828cb4fdccee10e9453adc46d284f0ed308244ee4d116ac731808d23e5c36fd73933eadc3e026ad535b78ac681c2daee30167cf9baca9c56f661c746b5040fb17c04392b8c41885da5c5de7a131c00469f688ce8613719252ed3e1612ce7b32c61a02e652426c96a861ca8e3d6727cb009723fca95e7bce8d0b1a946b29388a65bd7d3173bd6ac39515007e42bf34cf19a990ea89d8d34bf2ff8f44c97d513768af12588fdfcd229732a02fddfb82f405258f55366f46732332d30436d982dcbce720c0bab217a79235a845c7c8bfecec1a91e1635bd689c1c444f4fe84e8c951614f2cf747662c63f1c1c665147e371ee76d4f72dd73020222ffce6936386d7b5be96f37cc0043ec9049b24e6425f41912a4ec63b930b3ff437fae541f0321c36e4355a2afbb05536bd694eae74a76cc46182d86d8120c44e8e23acd692d647876ef14d4031f9f078a2fbe1d98665842952f9b766639cb30f1c1d232ed3c2df679dc3dde8e31d7577b980c45ba3b99c8a642c69f718b8066e25b38848ebd6f7c71169c57a24a3bf2d5fd36178cc5b8dc9c22534311f3422713fea55a3e047664e8d02af980792e6e308b1eae26c98d705a1325*